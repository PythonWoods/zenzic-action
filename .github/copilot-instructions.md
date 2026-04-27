<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# ⚡ ZENZIC ACTION — Obsidian Ledger v1.0 / Zenzic v0.7.0

> **Single Source of Truth for all agents and contributors to the zenzic-action repository.**
> Schema: [MANIFESTO] → [POLICIES] → [ARCHITECTURE] → [ADR] → [ACTIVE SPRINT] → [ARCHIVE LINK]

---

## [MANIFESTO] — The CI Gate at the World's Pipelines

`zenzic-action` is the official bridge between Markdown documentation sources and GitHub Security. It is not a wrapper — it is the **avamposto** (forward operating post) of Zenzic in every GitHub Actions pipeline that adopts it.

**Tagline:** *"The official bridge between your Markdown sources and GitHub Security."*

**What it does:**
- Runs `zenzic check all` as a CI gate on every push and pull request.
- Outputs findings in **SARIF 2.1.0** for native integration with GitHub Code Scanning.
- Surfaces findings as:
  - Security tab entries in the GitHub repository
  - Inline PR annotations (colour-coded by severity)
  - GitHub Code Scanning dashboard findings
- Enforces the Zenzic **exit code contract** — security incidents are **never suppressible**.

**Target users:** DevOps engineers, repository maintainers, security teams integrating documentation quality into CI.

---

## [CLOSING PROTOCOL] — Mandatory Sprint Closure Checklist

> **[MANDATORY]** A sprint is not closed until every step below is complete.
> Skipping any step is a **Class 1 violation (Technical Debt)** — the successor agent inherits a ghost, not a project.

### Step 0 — Pre-Task Alignment

- [ ] Read the **[POLICIES]** section of this ledger before starting any work.
- [ ] The **Law of Contemporary Testimony (CEO-059)** applies unconditionally: code and documentation are a single indivisible unit. No task is complete until both are aligned.

### Step 1 — Update This File
- [ ] New architectural facts? → Update **[ARCHITECTURE]**
- [ ] New decisions made? → Add an **[ADR]** entry (tagged `[DECISION]`)
- [ ] Bug found and fixed? → Promote the lesson to a **[POLICY]** rule or **[ADR]** (permanent invariants only). Update **[ACTIVE SPRINT]**.
- [ ] Sprint complete? → Update **[ACTIVE SPRINT]**. Purge previous-sprint entry to `CHANGELOG.md` in core repo.
- [ ] **Size Guardrail:** This file exceeds 400 lines? → Trigger a curation task (Law of Evolutionary Curation).
### Step 2 — Update README
- [ ] `README.md` — check: action inputs/outputs table, `version:` examples, usage YAML snippets, exit code table
- [ ] **Executive Filter:** Core repo `RELEASE.md` must stay ≤ 200 lines (Law of Executive Brevity). Action-visible changes only; no internal sprint IDs or bug references.

### Step 3 — Staleness & Testimony Audit
- [ ] Input defaults changed? → README inputs table + `action.yml` must be in sync
- [ ] Exit code contract changed? → README + [POLICIES] exit code table
- [ ] New Zenzic CLI flags exposed as action inputs? → `action.yml`, wrapper script, and README all updated
- [ ] `zenzic-action-wrapper.sh` logic changed? → Update execution flow diagram in [ARCHITECTURE]
- [ ] **Contemporary Check (CEO-059):**
  - New action input or output? → `README.md` inputs/outputs table + `action.yml`
  - Wrapper script behavior changed? → [ARCHITECTURE] execution flow diagram in this file
  - Exit code semantics changed? → Exit code table in [POLICIES] AND `README.md`
  - New Zenzic version capability exposed? → Usage examples in `README.md`
- [ ] **Testimony check** — `README.md` accurately describes the current inputs, outputs, and execution flow

### Step 4 — Verification Gate
- [ ] Self-check workflow: push to branch and confirm `self-check.yml` passes
- [ ] `action.yml` inputs match `zenzic-action-wrapper.sh` variable consumption
- [ ] `zenzic-action-wrapper.sh` outputs written to `$GITHUB_OUTPUT` before any `exit` call (output-first semantics)

---

## [POLICIES] — Immutable Operational Laws

### The Law of Contemporary Testimony [MANDATORY] — CEO-059

- **[INVARIANT] Action Behavior and README are a single, indivisible unit of work.**
  - **No Silent Logic:** Any change to action inputs, outputs, wrapper behavior, or exit code semantics MUST be reflected in `README.md` within the SAME sprint/task.
  - **Verification:** An agent is NOT permitted to signal "Task Complete" if `README.md` reflects old behavior.
  - **Sovereignty:** Before starting ANY task, the agent MUST read this ledger. This file is the only source of truth for current project policies.

### Exit Code Contract (Non-Negotiable)

| Exit | Meaning | Suppressible by `fail-on-error: false`? |
|------|---------|----------------------------------------|
| 0 | All checks passed — documentation is clean | — |
| 1 | Quality findings (broken links, orphans, placeholders, etc.) | ✅ Yes — respects `fail-on-error` |
| 2 | Shield security breach — credential detected (Z201) | ❌ **Never** |
| 3 | Blood Sentinel — system path traversal / fatal (Z202/Z203) | ❌ **Never** |

**[INVARIANT]** Exit codes 2 and 3 bypass `fail-on-error: false`. They are always fatal. There is no flag, input, or configuration that can suppress a security incident.

### SARIF Integrity

- **[RULE]** Validate SARIF JSON before uploading to GitHub Code Scanning. A truncated SARIF file (caused by SIGKILL, OOM, or runner crash) must be detected and emitted as a `::warning` annotation — never uploaded silently as a false-clean result.
- **[RULE]** If a security incident is detected (exit 2/3) but zero findings were parsed from SARIF (race condition or crash), force `findings-count=1`. Never report "0 findings" when Zenzic exited with a security code.

### Output-First Semantics

- **[INVARIANT]** All GitHub Action outputs (`sarif-file`, `findings-count`) must be written to `$GITHUB_OUTPUT` **before any `exit` call**. This guarantees GitHub Code Scanning receives results even when the workflow step fails.

### Version Strategy

- **[RULE]** Default `version: latest` is suitable for development and exploration. For production pipelines, **always pin to a specific release** (e.g., `version: "0.7.0"`) for deterministic, reproducible CI gates.
- **Mechanism:** `latest` → `uvx zenzic`. Any other value → `uvx "zenzic==<version>"`.

### Zero Python Toolchain Dependency

- **[INVARIANT]** The action uses `uvx` via `astral-sh/setup-uv` for isolated execution. No pre-installed Python or pip is required on the runner. This is a core design principle — do not add steps that assume Python toolchain presence.

### Documentation Law — The Obsidian Testimony [MANDATORY]

- **[INVARIANT] Any change to action inputs, outputs, wrapper script behavior, or exit code semantics must be reflected in `README.md` before the sprint is closed.** A wrapper change without a README update is a ghost commit.
- **Trigger rules (mandatory — not optional):**
  - New input or output added to `action.yml` → Update `README.md` inputs/outputs table
  - `zenzic-action-wrapper.sh` logic changed → Update execution flow diagram in [ARCHITECTURE]
  - Exit code semantics changed → Update exit code table in [POLICIES] AND `README.md`
  - New Zenzic version capabilities exposed via action inputs → Update usage examples in `README.md`
- **Enforcement:** The [CLOSING PROTOCOL] Step 3 (Staleness & Testimony Audit) implements this law. **A sprint without a Testimony check is not closed.**

### Memory Law — The Custodian's Contract

- **[INVARIANT] The [CLOSING PROTOCOL] is a non-negotiable Engineering Contract.**
  An agent that ends a session without completing it commits a Class 1 violation (Technical Debt). The successor inherits a ghost, not a project.
- **[INVARIANT] This file is the agent's only persistent memory.** Update it before the final commit — not after.
- **[INVARIANT] Definition of Done:** A sprint is not closed until README is current and the staleness audit is complete.
- **[INVARIANT] Sovereignty:** This file is the single source of truth for agent behavior in this repository.

### The Law of Executive Brevity [MANDATORY] — D068

- **[INVARIANT] Core repo `RELEASE.md` must never exceed 200 lines.**
  - User-visible narrative only: features, security wins, breaking changes, install CTA.
  - No mutation tables, internal sprint IDs, bug IDs, or CVE traces.
  - Technical details belong in `CHANGELOG.md` (core repo), not in release notes.
- **[RULE]** Action release notes in `README.md` follow the same discipline: inputs/outputs changes only; no internal identifiers.
- **Enforcement:** [CLOSING PROTOCOL] Step 2 "Executive Filter" check implements this law.

---

## [ARCHITECTURE] — Action Structure

```
zenzic-action/
  action.yml                     — GitHub Action manifest (composite action)
  zenzic-action-wrapper.sh       — Core execution layer (131 lines; bash)
  package.json                   — Node.js metadata (version: 1.0.0; Node ≥24 required)
  README.md                      — Full user documentation
  assets/                        — SVG branding/UI assets
  .github/
    workflows/
      self-check.yml             — Integration test: action runs on itself
    copilot-instructions.md      — This file
```

### Action Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `version` | `latest` | Zenzic CLI version to install (`latest` or e.g. `"0.7.0"`) |
| `format` | `sarif` | Output format: `text`, `json`, or `sarif` |
| `sarif-file` | `zenzic-results.sarif` | Output SARIF file path (when `format: sarif`) |
| `upload-sarif` | `true` | Upload SARIF to GitHub Code Scanning |
| `strict` | `false` | Treat warnings as errors (`--strict` flag) |
| `fail-on-error` | `true` | Fail the workflow step on quality findings (exit 1). Does NOT affect exit 2/3. |

### Action Outputs

| Output | Description |
|--------|-------------|
| `sarif-file` | Path to the generated SARIF file |
| `findings-count` | Total number of findings reported |

### Execution Flow (zenzic-action-wrapper.sh)

```
1. Build package spec:  "zenzic" (latest) or "zenzic==X.Y.Z" (pinned)
2. Run uvx with optional --strict flag
3. Capture exit code
4. If exit 2 or 3:
     → Set findings-count=1 if SARIF shows 0 (coherence guard)
     → Write to $GITHUB_OUTPUT (output-first semantics)
     → Exit with original security code (non-suppressible)
5. If exit 1 and fail-on-error=false:
     → Write outputs
     → Exit 0 (quality suppressed by user choice)
6. Validate SARIF JSON integrity before upload:
     → Truncated JSON → emit ::warning annotation
7. Upload SARIF to GitHub Code Scanning (if upload-sarif=true)
8. Write final outputs to $GITHUB_OUTPUT
9. Exit with resolved code
```

### Supported Environments

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| GitHub-hosted runner | `ubuntu-22.04` | `ubuntu-latest` |
| `astral-sh/setup-uv` | v8 | latest |
| `github/codeql-action/upload-sarif` | v3 | latest |
| `actions/checkout` | v6 | latest |
| Node.js (runner) | 24 | latest |
| Self-hosted | Any OS with `bash ≥5`, `python3 ≥3.11` | — |

---

## [ADR] — Architectural Decision Records

### ADR-001: Composite Action Architecture (Not Docker, Not JS)
**[DECISION]** `zenzic-action` is a composite action using shell script — not a Docker container, not a JavaScript action.
- **Why Docker was rejected:** Container image pull adds 15–60 seconds of latency per run. Composite + `uvx` achieves isolated execution with near-zero startup overhead.
- **Why JS was rejected:** JavaScript actions require bundling and Node.js. The action's logic is inherently shell/Python — a JS wrapper adds complexity without benefit.
- **Result:** A single `zenzic-action-wrapper.sh` script, invoked directly by the runner's bash. Total action overhead: ~3 seconds (`uvx` cache warm) or ~8 seconds (cold install).

### ADR-002: Non-Suppressible Exit Codes for Security Incidents
**[DECISION]** Exit codes 2 (Shield) and 3 (Blood Sentinel) are never suppressible by any user-facing input.
- **Why:** A CI gate that can be told to ignore credential leaks provides false safety. The value of the action is unconditional security enforcement.
- **Implementation:** `zenzic-action-wrapper.sh` checks exit code before consulting `fail-on-error`. If exit is 2 or 3, it propagates unconditionally.
- **User contract:** `fail-on-error: false` only suppresses exit 1 (quality findings). It has no effect on security exits.

### ADR-003: Version Flexibility — User-Controlled at Call Site
**[DECISION]** The action does not pin a Zenzic version internally. The user controls pinning via the `version` input.
- **Why:** Different repos have different release cadences. Some want `latest` for continuous improvement; production CI needs deterministic pinning. Centralising the pin in the action would force all users onto the same version regardless of need.
- **Recommendation:** Use `version: "0.7.0"` (or current stable) in production pipelines.

### ADR-004: Output-First Semantics — Always Write Before Exit
**[DECISION]** All `$GITHUB_OUTPUT` writes happen before any `exit` call, including on security failures.
- **Why:** GitHub Actions output variables are only propagated if the step writes them before termination. A step that exits before writing outputs leaves downstream jobs with undefined/empty values, making it impossible to reference `findings-count` in subsequent steps or summary displays.
- **Implementation:** Wrapper uses a `finally`-equivalent pattern: outputs written, then exit called.

### ADR-005: SARIF Integrity Validation
**[DECISION]** The wrapper validates SARIF JSON with a Python one-liner before declaring the upload safe.
- **Why:** If Zenzic is killed by OOM or SIGKILL mid-run, the SARIF file is truncated. Uploading truncated JSON to Code Scanning silently produces a "0 findings" result — a false clean signal that masks real security issues.
- **Implementation:** `python3 -c "import json, sys; json.load(open('${SARIF_FILE}'))"` — if this raises, emit `::warning` and skip upload.

---

## [ACTIVE SPRINT] — Working Context

### D074+D075 — Coverage Iron Gate + R19 Testimony (Current)

**Version:** 1.0 · **Date:** 2026-04-25

No action changes in this sprint. Core: 3 targeted tests for `_first_content_line()` multi-line
comment paths push total coverage to 80.00%. Docs: R19 `:::warning` admonition added to
`configuration-reference.mdx` (EN + IT). All v0.7.0 governance obligations fulfilled.

**Cross-repo note (CEO 056/058/060 — 2026-04-27):** zenzic-doc blog standardized to
"🛡️ Saga X" naming scheme + Tutorial "Stop Broken Links in 60s" published. BUG-004
(Frontmatter Supremacy) codified in zenzic-doc policies. No action code changes required.

### Last Closed — D073 — The Law of Evolutionary Curation

**Version:** 1.0 · **Date:** 2026-04-25

All three Obsidian Ledgers refactored from "historical diaries" to "operational manuals".
[CHRONICLES] empty stub removed. [SPRINT LOG] replaced by [ACTIVE SPRINT] (2-sprint window).
Law of Evolutionary Curation codified in [POLICIES]. Schema updated across all three repos.

---

## [ARCHIVE LINK]

Complete sprint history and action design decisions:

- **[CHANGELOG.md](https://github.com/PythonWoods/zenzic/blob/main/CHANGELOG.md)** — core release cycle (v0.7.0)
- **[CHANGELOG.archive.md](https://github.com/PythonWoods/zenzic/blob/main/CHANGELOG.archive.md)** — pre-v0.6.0 history
