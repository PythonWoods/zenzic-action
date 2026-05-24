#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
#
# zenzic-action-wrapper.sh — Strict execution layer for the Zenzic GitHub Action.
#
# Responsibilities:
#   1. Run `uvx zenzic check all` with the caller's parameters.
#   2. Validate SARIF JSON integrity before declaring success — a SIGKILL or
#      Python runtime abort can produce a truncated file that breaks the upload.
#   3. Write all GitHub Action outputs BEFORE any exit — Code Scanning always
#      receives findings, even when the build fails with a security incident.
#   4. Enforce the Zenzic Exit Code Contract with coherent UX:
#        0  — clean (all checks passed)
#        1  — documentation findings (broken links, orphan pages, dead refs, etc.)
#        2  — SECURITY: credential detected — credential scanner / Z201 — NEVER suppressed
#        3  — SECURITY: system path traversal — path traversal guard / Z202-203 — NEVER suppressed
#        4  — QUALITY REGRESSION: zenzic diff detected a score drop vs baseline — blocks PR merge
#
#      For exit codes 2 and 3: if no findings were parsed from the SARIF file
#      (because the breach was detected before scanning completed), findings-count
#      is forced to 1 — the security incident itself — so the output remains
#      coherent with the failing build. A caller who sees "0 findings but exit 2"
#      is an inconsistent UX we refuse to ship.
#
# Environment variables consumed (injected by action.yml):
#   ZENZIC_VERSION       Zenzic release to install ("latest" or "0.7.0", etc.)
#   ZENZIC_FORMAT        Output format: text | json | sarif
#   ZENZIC_SARIF_FILE    Path for SARIF output file (default: zenzic-results.sarif)
#   ZENZIC_STRICT        "true" → pass --strict flag (warnings become errors)
#   ZENZIC_FAIL_ON_ERROR "true" → propagate exit 1 to the workflow step
#   ZENZIC_CONFIG_FILE   Explicit config path (optional). If empty, auto-discovers
#                        .zenzic.toml (root) → .github/.zenzic.toml (fallback).
#   ZENZIC_AUDIT         "true" → pass --audit flag (bypasses all suppressions)
#   ZENZIC_DIFF_BASE     Path to a JSON baseline file for zenzic diff comparison.

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
ZENZIC_VERSION="${ZENZIC_VERSION:-latest}"
ZENZIC_FORMAT="${ZENZIC_FORMAT:-sarif}"
ZENZIC_SARIF_FILE="${ZENZIC_SARIF_FILE:-zenzic-results.sarif}"
ZENZIC_STRICT="${ZENZIC_STRICT:-false}"
ZENZIC_FAIL_ON_ERROR="${ZENZIC_FAIL_ON_ERROR:-true}"
ZENZIC_CONFIG_FILE="${ZENZIC_CONFIG_FILE:-}"
ZENZIC_AUDIT="${ZENZIC_AUDIT:-false}"
ZENZIC_DIFF_BASE="${ZENZIC_DIFF_BASE:-}"

# ── SARIF path sandbox guard (BUG-006 — Action SARIF Jailbreak) ────────────────
# The sarif-file input is an output path. Any relative traversal (../../) or
# absolute path (/) would allow a workflow to write outside the checkout
# directory. This guard is the shell-level path traversal enforcer for the action layer.
case "${ZENZIC_SARIF_FILE}" in
  /*)
    echo "::error title=Zenzic — SARIF Jailbreak::sarif-file must be a relative path inside the workspace. Absolute paths are forbidden. Got: '${ZENZIC_SARIF_FILE}'" >&2
    exit 1
    ;;
  *../*|*/..|..)
    echo "::error title=Zenzic — SARIF Jailbreak::sarif-file must not contain path traversal sequences ('..').  Got: '${ZENZIC_SARIF_FILE}'" >&2
    exit 1
    ;;
esac

# ── Package spec ──────────────────────────────────────────────────────────────
# "latest" → bare `zenzic` so uvx resolves the most recent stable release.
# Any other value is treated as an exact version pin: `zenzic==0.7.0`.
PKG="zenzic"
if [ "${ZENZIC_VERSION}" != "latest" ]; then
  PKG="zenzic==${ZENZIC_VERSION}"
fi

# ── Optional flags ────────────────────────────────────────────────────────────
STRICT_FLAG=""
if [ "${ZENZIC_STRICT}" = "true" ]; then
  STRICT_FLAG="--strict"
fi

AUDIT_FLAG=""
if [ "${ZENZIC_AUDIT}" = "true" ]; then
  AUDIT_FLAG="--audit"
fi

# ── diff-base sandbox guard ───────────────────────────────────────────────────
# diff-base is a path to a JSON file inside the workspace. Reject absolute
# paths and path traversal sequences to prevent reading files outside the checkout.
DIFF_BASE_ARGS=()
if [ -n "${ZENZIC_DIFF_BASE}" ]; then
  case "${ZENZIC_DIFF_BASE}" in
    /*)
      echo "::error title=Zenzic — diff-base Jailbreak::diff-base must be a relative path inside the workspace. Absolute paths are forbidden. Got: '${ZENZIC_DIFF_BASE}'" >&2
      exit 1
      ;;
    *../*|*/..|..)
      echo "::error title=Zenzic — diff-base Jailbreak::diff-base must not contain path traversal sequences ('..').  Got: '${ZENZIC_DIFF_BASE}'" >&2
      exit 1
      ;;
  esac
  if [ -f "${ZENZIC_DIFF_BASE}" ]; then
    DIFF_BASE_ARGS=(--base "${ZENZIC_DIFF_BASE}")
  else
    echo "::warning title=Zenzic — diff-base Not Found::diff-base '${ZENZIC_DIFF_BASE}' does not exist. Falling back to saved .zenzic-score.json snapshot." >&2
  fi
fi

# ── Config file cascade (Root-First discovery) ──────────────────────────────
# Discovery order (highest → lowest priority):
#   1. Explicit override  — ZENZIC_CONFIG_FILE set by the caller (config-file input)
#   2. Standard root      — .zenzic.toml in the workspace root
#   3. Hidden fallback    — .github/.zenzic.toml
#
# The Sandbox Guard (path traversal / absolute path rejection) applies ONLY to
# explicit overrides: auto-discovered paths are hardcoded in this script and
# cannot be injected by an attacker, so guarding them is both unnecessary and
# misleading.
#
# Sovereign Intent Contract: when the caller provides an explicit config-file
# path that does not exist, auto-discovery is SUPPRESSED.  Silently falling
# through to a different config would violate the caller's explicit intent
# ("operational deception").  Instead:
#   • strict mode → ::error + exit 1  (missing explicit config is fatal)
#   • default mode → ::warning        (visible in the log; Zenzic uses its
#                                      own internal defaults, NOT auto-discovery)
CONFIG_ARGS=()
CANDIDATE_CONFIG=""

if [ -n "${ZENZIC_CONFIG_FILE}" ]; then
  # ── Sandbox Guard — explicit paths only ────────────────────────────────────
  case "${ZENZIC_CONFIG_FILE}" in
    /*)
      echo "::error title=Zenzic — Config Jailbreak::config-file must be a relative path inside the workspace. Absolute paths are forbidden. Got: '${ZENZIC_CONFIG_FILE}'" >&2
      exit 1
      ;;
    *../*|*/..|..)
      echo "::error title=Zenzic — Config Jailbreak::config-file must not contain path traversal sequences ('..').  Got: '${ZENZIC_CONFIG_FILE}'" >&2
      exit 1
      ;;
  esac
  if [ -f "${ZENZIC_CONFIG_FILE}" ]; then
    CANDIDATE_CONFIG="${ZENZIC_CONFIG_FILE}"
  else
    # Explicit override supplied but file absent — sovereign intent must not be
    # silently reassigned to a different config.  Auto-discovery is suppressed.
    if [ "${ZENZIC_STRICT}" = "true" ]; then
      echo "::error title=Zenzic — Config Not Found::config-file '${ZENZIC_CONFIG_FILE}' was specified but does not exist. In strict mode a missing explicit configuration is a fatal error." >&2
      exit 1
    else
      echo "::warning title=Zenzic — Config Not Found::config-file '${ZENZIC_CONFIG_FILE}' was specified but does not exist. Auto-discovery is suppressed — Zenzic will use its internal defaults." >&2
    fi
    # CANDIDATE_CONFIG remains ""; CONFIG_ARGS stays empty.
  fi
elif [ -f ".zenzic.toml" ]; then
  CANDIDATE_CONFIG=".zenzic.toml"
elif [ -f ".github/.zenzic.toml" ]; then
  CANDIDATE_CONFIG=".github/.zenzic.toml"
fi

if [ -n "${CANDIDATE_CONFIG}" ]; then
  CONFIG_ARGS=(--config "${CANDIDATE_CONFIG}")
fi

# ── Extra args passthrough (Sovereign Override) ──────────────────────────────
# ZENZIC_EXTRA_ARGS is set by the caller's workflow (e.g. --exclude-url …).
# Word-split intentionally: each --exclude-url <url> pair must become separate
# argv elements.  set -f disables glob expansion so that wildcards or '?'
# characters inside URLs are never expanded against the filesystem.
set -f                                  # disable globbing (glob-safe construction)
# shellcheck disable=SC2206
EXTRA_ARGS=(${ZENZIC_EXTRA_ARGS:-})    # intentional IFS word-split
set +f                                  # restore globbing

EXIT_CODE=0
FINDINGS=0

# ── Execute ───────────────────────────────────────────────────────────────────
if [ "${ZENZIC_FORMAT}" = "sarif" ]; then
  # SARIF path: capture stdout to file; stderr streams to the step log.
  # `|| EXIT_CODE=$?` captures the exit code without triggering set -e.
  uvx "${PKG}" check all --format sarif "${CONFIG_ARGS[@]}" ${STRICT_FLAG} ${AUDIT_FLAG} "${EXTRA_ARGS[@]}" \
    > "${ZENZIC_SARIF_FILE}" \
    || EXIT_CODE=$?

  # Emit SARIF path immediately — the upload step needs it regardless of outcome.
  echo "sarif-file=${ZENZIC_SARIF_FILE}" >> "${GITHUB_OUTPUT}"

  # ── SARIF integrity check ─────────────────────────────────────────────────
  # A SIGKILL or Python runtime abort can truncate the JSON mid-write.
  # Validate before parsing so the upload step can surface an accurate warning
  # instead of a cryptic GitHub API error.
  if ! python3 -c "import json, os; json.load(open(os.environ['ZENZIC_SARIF_FILE']))" 2>/dev/null; then
    echo "::warning title=Zenzic — SARIF truncated::The file '${ZENZIC_SARIF_FILE}' is not valid JSON. The process was likely aborted before completing the write (SIGKILL or runtime crash). GitHub Code Scanning upload may fail — check the step log for the true root cause." >&2
    # FINDINGS stays 0; the broken SARIF is still handed to the upload step,
    # which will surface its own error with the precise GitHub API message.
  else
    # Parse finding count only when the SARIF is structurally valid.
    FINDINGS=$(python3 - <<PYEOF || true
import json, os
try:
    with open(os.environ["ZENZIC_SARIF_FILE"]) as f:
        data = json.load(f)
    print(len(data["runs"][0]["results"]))
except Exception:
    print(0)
PYEOF
)
    FINDINGS="${FINDINGS:-0}"
  fi

else
  # Non-SARIF: stream output directly to the step log; capture exit code.
  uvx "${PKG}" check all --format "${ZENZIC_FORMAT}" "${CONFIG_ARGS[@]}" ${STRICT_FLAG} ${AUDIT_FLAG} "${EXTRA_ARGS[@]}" \
    || EXIT_CODE=$?

fi

# ── Zenzic Quality Gate: zenzic diff ─────────────────────────────────────────
# Run diff to detect score regression vs the baseline. Writes score and
# suppression-debt-pts to GITHUB_OUTPUT for downstream steps.
# Only runs when format is json (score snapshot is available) or when
# diff-base is explicitly provided. Skipped in audit mode.
SCORE=""
DEBT_PTS="0"
if [ "${ZENZIC_AUDIT}" != "true" ] && [ "${EXIT_CODE}" -eq 0 ] || [ "${EXIT_CODE}" -eq 1 ]; then
  if [ "${ZENZIC_FORMAT}" = "json" ] || [ -n "${ZENZIC_DIFF_BASE}" ]; then
    DIFF_EXIT=0
    DIFF_OUTPUT=""
    DIFF_OUTPUT=$(uvx "${PKG}" diff --format json "${DIFF_BASE_ARGS[@]}" 2>/dev/null) || DIFF_EXIT=$?

    if [ -n "${DIFF_OUTPUT}" ]; then
      SCORE=$(echo "${DIFF_OUTPUT}" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('current_score', ''))
except Exception:
    print('')
" 2>/dev/null || true)
      DEBT_PTS=$(echo "${DIFF_OUTPUT}" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('suppression_debt_pts', 0))
except Exception:
    print(0)
" 2>/dev/null || true)
      DEBT_PTS="${DEBT_PTS:-0}"
    fi

    # Exit 4 = quality regression (score dropped vs baseline)
    if [ "${DIFF_EXIT}" -eq 4 ]; then
      echo "score=${SCORE}" >> "${GITHUB_OUTPUT}"
      echo "suppression-debt-pts=${DEBT_PTS}" >> "${GITHUB_OUTPUT}"
      echo "findings-count=${FINDINGS}" >> "${GITHUB_OUTPUT}"
      echo "::error title=Zenzic Quality Regression — Exit 4::Documentation quality score dropped vs baseline. The Zenzic Quality Gate blocked this PR. Check 'zenzic diff' output for details." >&2
      exit 4
    fi
  fi
fi

# ── Exit Code Contract ────────────────────────────────────────────────────────
# Security incidents (exit 2 and 3) are NEVER suppressed — not even by
# fail-on-error: "false". All GitHub Action outputs are written before exit.
#
# If FINDINGS is 0 but the exit code signals a security incident, the breach
# was detected before scanning completed (e.g. during config load). Override
# findings-count to 1 — the incident itself — to preserve output coherence.
# The ::error annotation explicitly states that checks were aborted.

if [ "${EXIT_CODE}" -eq 2 ]; then
  [ "${FINDINGS}" -eq 0 ] && FINDINGS=1
  echo "findings-count=${FINDINGS}" >> "${GITHUB_OUTPUT}"
  echo "score=${SCORE}" >> "${GITHUB_OUTPUT}"
  echo "suppression-debt-pts=${DEBT_PTS}" >> "${GITHUB_OUTPUT}"
  echo "::error title=Zenzic Credential Scanner — Z201::Credential pattern detected. Scan aborted at breach point — findings-count=${FINDINGS} (security incident). Exit 2 is non-suppressible per the Zenzic Exit Code Contract." >&2
  exit 2
fi

if [ "${EXIT_CODE}" -eq 3 ]; then
  [ "${FINDINGS}" -eq 0 ] && FINDINGS=1
  echo "findings-count=${FINDINGS}" >> "${GITHUB_OUTPUT}"
  echo "score=${SCORE}" >> "${GITHUB_OUTPUT}"
  echo "suppression-debt-pts=${DEBT_PTS}" >> "${GITHUB_OUTPUT}"
  echo "::error title=Zenzic Path Traversal Guard — Z202/Z203::System path traversal detected. Scan aborted at breach point — findings-count=${FINDINGS} (security incident). Exit 3 is non-suppressible per the Zenzic Exit Code Contract." >&2
  exit 3
fi

# Write all outputs for non-security exits (covers both sarif and non-sarif runs).
echo "findings-count=${FINDINGS}" >> "${GITHUB_OUTPUT}"
echo "score=${SCORE}" >> "${GITHUB_OUTPUT}"
echo "suppression-debt-pts=${DEBT_PTS}" >> "${GITHUB_OUTPUT}"

# Exit code 1 (documentation findings) respects the caller's fail-on-error policy.
if [ "${ZENZIC_FAIL_ON_ERROR}" = "true" ] && [ "${EXIT_CODE}" -ne 0 ]; then
  exit "${EXIT_CODE}"
fi

exit 0
