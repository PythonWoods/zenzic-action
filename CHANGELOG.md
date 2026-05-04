<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [1.0.0] — 2026-05-XX (Target) — Quartz Edition (Stable)

> The official GitHub Action for [Zenzic](https://github.com/PythonWoods/zenzic),
> the deterministic documentation quality gate.

### 💎 Quartz Era (Initial Stable Release)

This release establishes zenzic-action as a **stable, self-contained distribution
channel** for the Zenzic Sentinel. The Action is decoupled from the core development
cycle and pinned exclusively to released versions via `uvx zenzic@v0.7.0`.

#### Added

- **Composite GitHub Action** (`action.yml`): Installs Zenzic via `uv tool install`,
  runs `check all` with configurable format, and optionally uploads SARIF results to
  GitHub Code Scanning.
- **Configurable Inputs**: `version`, `format` (`text`/`json`/`sarif`), `sarif-file`,
  `upload-sarif`, `strict`, `fail-on-error`.
- **Structured Outputs**: `sarif-file` path and `findings-count` for downstream steps.
- **Path Traversal Guard**: `zenzic-action-wrapper.sh` rejects absolute paths and `..`
  sequences in `sarif-file` input, preventing write-outside-workspace attacks.
- **SARIF Integration**: Native `github/codeql-action/upload-sarif@v4` step surfaces
  findings inline in PR diffs and the repository Security tab.
- **4-Gates Standard**: `just verify` runs `reuse` + `check` + `preflight` + `test`
  identically in local and CI environments.
- **REUSE/SPDX Compliance**: All files carry inline SPDX headers. `REUSE.toml`
  covers generated artefacts.
- **Version Bump Automation**: `scripts/bump-version.sh` updates `action.yml` and
  `README.md` version references atomically.

#### Architecture

- **Stable Pin Policy**: The Action invokes `uvx zenzic@v0.7.0` — never unreleased
  code. This guarantees that downstream users always run against tested, tagged binaries.
- **Zero Dynamic Coupling**: No checkout of the core repository. No `ZENZIC_PROJECT_PATH`.
  No branch parity. The Action is a sealed distribution artefact.
- **Self-Check CI** (`self-check.yml`): Validates the Action's own documentation using
  the same stable Zenzic pin.
