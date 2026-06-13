<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to zenzic-action are documented in this file. The project adheres to Semantic Versioning. Major releases represent breaking changes to inputs/outputs, minor releases introduce new options or core package bumps, and patch releases address bug fixes. Format follows Keep a Changelog.

---

## [2.0.0] - 2026-06-13

### Changed (Breaking)

- **Dropped Docusaurus Support**: Upgraded the pinned Zenzic Core to `v0.12.0`, which surgically eradicates the Docusaurus adapter due to ontological incompatibility (React-injected IDs and MDX partial merging). Projects still relying on Docusaurus MUST remain on the `v1` floating tag (`v1.3.x`).
- **Major Version Bump**: The action major version is bumped to `v2` to prevent breaking existing Docusaurus consumers tracking `v1`.

---

## Historical Releases

- v1.3.x archive: [changelogs/v1.3.md](./changelogs/v1.3.md)
- Archive index: [changelogs/README.md](./changelogs/README.md)
