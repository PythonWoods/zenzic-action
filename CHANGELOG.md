<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

No changes yet.

---

## [1.3.4] - 2026-06-09

### Changed

- **Operational governance docs:** Added explicit branch-protection policy to `README.md` and `README.it.md`, including required checks for `main` (`Verify (ubuntu-latest, true)`, `Lint PR Title`, `Check DCO`) and fail-closed workflow selection rules.
- **Core pin:** Zenzic Core pinned to `0.10.4`.

---

## [1.3.4] - 2026-06-07

### Changed

- Disabled dependency caching in `setup-uv` to prevent noisy warnings on non-Python repositories.

---

## [1.3.4] - 2026-06-07

### Deprecated

- **Versions v1.3.0 and older are officially deprecated.** They contained a critical bug in the bash wrapper that injected an invalid `--config` flag, causing false-positive Exit 2 crashes. Users pinned to exact patch versions must upgrade to `v1.3.1` or use the major tag `@v1`.

### Added

- `guard-scan` input: run `zenzic guard scan` before the main quality gate.
- `cap-exceeded` output: exposes suppression-cap failures for downstream workflow logic.
- Sovereign Job Summary output for every critical non-zero exit code.

### Changed

- Runtime governance parity: wrapper executes score governance checks after `check all`.
- ADR-037 alignment: `release_name` in `.zenzic.toml` set to semantic version form.
- ADR-089 alignment: GitHub Actions dependencies pinned to immutable SHA-40.
- Final Guard documentation aligned to the actual `just verify` recipe sequence.

### Security

- Explicitly documented non-suppressible action boundary for exits 2 and 3.
- Forwarding contract for security-related runtime flags is enforced end-to-end.
- Inherited governance semantics from core: additive `brand_obsolescence` merge behavior.
