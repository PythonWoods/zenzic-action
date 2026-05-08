<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added

- **DX Release Recipes (Sprint DX):** All four ecosystem repositories now include:
  - `just version` — prints current action version from bump-my-version
  - `just core-version` — prints pinned Zenzic Core version (from Comment Anchor in action.yml)
  - `just versions` — prints both action and core versions side-by-side
  - `just release-dry <part>` — full verbose dry-run (shows file diffs)
  - `just release-dry <part> --short` — compact preview (3 essential lines only)
  - `just release-contracts` — validates justfile and action.yml architectural contracts, wired into `verify`
- **Comment Anchor Strategy — Core Pin Independence:** Zenzic Core version pin in `action.yml`
  (input `default:`) is marked with `# x-zenzic-core-pin` anchor. `just pin-core <version>`
  uses perl to update only this line, decoupling core pin from action version bumping via
  bump-my-version. Supports independent core patches without action version changes.
- **`_check-hooks` DX guard:** Added hidden `_check-hooks` recipe as first dependency of
  `just verify`. Emits a warning if the pre-push Final Guard hook (`pre-commit install
  -t pre-push`) is not installed locally, without blocking the verification run.

### Changed

- **`verify` recipe — `preflight` removed:** `verify` now runs `_check-hooks check test`.
  The obsolete `preflight` recipe (redundant alias for `uvx pre-commit run --all-files`)
  has been deleted from the justfile.

- **Infrastructure alignment checkpoint:** No code changes in this repository
  (shell-based composite action, `venv_backend="none"` throughout). This entry
  tracks alignment with the Zenzic Core v0.7.1 and Structum v0.1.1 infrastructure
  release (Boundary Testing matrix fix across the ecosystem).

---

## [1.0.1] — 2026-05-07 — Quartz Edition (Stable)

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

#### Changed

- **Matrix CI — Quartz Maturity**: `self-check.yml` now runs on `ubuntu-latest` and
  `windows-latest` (`fail-fast: false`, `defaults: run: shell: bash`). Cross-platform
  validation aligned with Core and Doc repos. `ZENZIC_EXTRA_ARGS` env block injected
  with `--exclude-url` entries for known pre-launch transient URLs.
- **Sovereign Override passthrough** (`zenzic-action-wrapper.sh`): `ZENZIC_EXTRA_ARGS`
  is now captured into an `EXTRA_ARGS` bash array and passed to both the SARIF and
  non-SARIF `uvx` invocations. Callers setting the 404 shield in their workflow env
  have it transparently forwarded to the Zenzic CLI — no more silent bypass.
- **`justfile` Bash-first**: `set shell := ["bash", "-c"]` added. `check *args` recipe
  expanded with `${ZENZIC_EXTRA_ARGS:-}` for local parity with CI propagation.
- **`.gitignore` hardening**: `.zenzic.dev.toml` added explicitly to prevent accidental
  tracking. `.zenzic.local.toml` was already ignored. Local `.zenzic.dev.toml` purged.
