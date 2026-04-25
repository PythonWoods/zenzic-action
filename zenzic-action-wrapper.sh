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
#        2  — SECURITY: credential detected — Shield / Z201 — NEVER suppressed
#        3  — SECURITY: system path traversal — Blood Sentinel / Z202-203 — NEVER suppressed
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

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
ZENZIC_VERSION="${ZENZIC_VERSION:-latest}"
ZENZIC_FORMAT="${ZENZIC_FORMAT:-sarif}"
ZENZIC_SARIF_FILE="${ZENZIC_SARIF_FILE:-zenzic-results.sarif}"
ZENZIC_STRICT="${ZENZIC_STRICT:-false}"
ZENZIC_FAIL_ON_ERROR="${ZENZIC_FAIL_ON_ERROR:-true}"

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

EXIT_CODE=0
FINDINGS=0

# ── Execute ───────────────────────────────────────────────────────────────────
if [ "${ZENZIC_FORMAT}" = "sarif" ]; then
  # SARIF path: capture stdout to file; stderr streams to the step log.
  # `|| EXIT_CODE=$?` captures the exit code without triggering set -e.
  uvx "${PKG}" check all --format sarif ${STRICT_FLAG} \
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
  uvx "${PKG}" check all --format "${ZENZIC_FORMAT}" ${STRICT_FLAG} \
    || EXIT_CODE=$?

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
  echo "::error title=Zenzic Shield — Z201::Credential pattern detected. Scan aborted at breach point — findings-count=${FINDINGS} (security incident). Exit 2 is non-suppressible per the Obsidian Exit Code Contract." >&2
  exit 2
fi

if [ "${EXIT_CODE}" -eq 3 ]; then
  [ "${FINDINGS}" -eq 0 ] && FINDINGS=1
  echo "findings-count=${FINDINGS}" >> "${GITHUB_OUTPUT}"
  echo "::error title=Zenzic Blood Sentinel — Z202/Z203::System path traversal detected. Scan aborted at breach point — findings-count=${FINDINGS} (security incident). Exit 3 is non-suppressible per the Obsidian Exit Code Contract." >&2
  exit 3
fi

# Write findings-count for non-security exits (covers both sarif and non-sarif runs).
echo "findings-count=${FINDINGS}" >> "${GITHUB_OUTPUT}"

# Exit code 1 (documentation findings) respects the caller's fail-on-error policy.
if [ "${ZENZIC_FAIL_ON_ERROR}" = "true" ] && [ "${EXIT_CODE}" -ne 0 ]; then
  exit "${EXIT_CODE}"
fi

exit 0
