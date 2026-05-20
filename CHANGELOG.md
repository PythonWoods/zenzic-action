<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Changed

- **ADR-037 compliance:** `release_name` in `zenzic.toml` updated from geological
  codename `"Basalt"` to version string `"v1.1.0"` — aligns with brand_obsolescence
  policy that forbids geological terms in committed configuration.
- **ADR-089 compliance:** GitHub Actions pinned to SHA-40 (`actions/checkout`,
  `github/codeql-action/upload-sarif`, `astral-sh/setup-uv`).

### Security

- **Action security posture aligned with core invariants:** non-suppressible
  exit codes (2, 3) and strict forwarding of security flags through the wrapper
  contract are now explicitly tracked in release notes.
- **Governance hardening (inherited from Core):** `[governance].brand_obsolescence` in `.zenzic.local.toml` now uses additive merge semantics. Local overrides can extend but never remove globally-configured brand protection terms.
---

## [1.0.1] — 2026-05-07 — Stable Release

> The official GitHub Action for [Zenzic](https://github.com/PythonWoods/zenzic),
> the deterministic documentation quality gate.

### 🛡️ v0.7.x Stable (Initial Stable Release)

This release establishes zenzic-action as a **stable, self-contained distribution
channel** for the Zenzic Action. The Action is decoupled from the core development
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
- **Repository Gate Parity (current model)**: Runtime distribution remains sealed and
  pin-based for downstream users, while the repository self-check CI now resolves
  branch parity against core and checks out `_zenzic_core` before verification.
- **Self-Check CI** (`self-check.yml`): Validates the Action's own documentation using
  the same sovereign local-core contract used by family repositories.

#### Changed

- **Matrix CI — Cross-Platform Validation**: `self-check.yml` now runs on `ubuntu-latest` and
  `windows-latest` (`fail-fast: false`, `defaults: run: shell: bash`). Cross-platform
  validation aligned with Core and Doc repos. `ZENZIC_EXTRA_ARGS` env block injected
  with `--exclude-url` entries for known pre-launch transient URLs.
- **Sovereign Override passthrough** (`zenzic-action-wrapper.sh`): `ZENZIC_EXTRA_ARGS`
  is now captured into an `EXTRA_ARGS` bash array and passed to both the SARIF and
  non-SARIF `uvx` invocations. Callers setting the 404 exclusion in their workflow env
  have it transparently forwarded to the Zenzic CLI — no more silent bypass.
- **`justfile` Bash-first**: `set shell := ["bash", "-c"]` added. `check *args` recipe
  expanded with `${ZENZIC_EXTRA_ARGS:-}` for local parity with CI propagation.
- **`.gitignore` hardening**: `.zenzic.dev.toml` added explicitly to prevent accidental
  tracking. `.zenzic.local.toml` was already ignored. Local `.zenzic.dev.toml` purged.
