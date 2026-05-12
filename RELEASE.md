<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Release Procedure — zenzic-action

This file describes the release process for the `zenzic-action` GitHub Action.

## Release Checklist

1. **Update core pin** — set `default: "<new-version>"` in `action.yml` (the `# x-zenzic-core-pin` marker).
2. **Bump action version** — run `just bump <version>` (e.g. `just bump 1.1.0`).
   This updates `package.json`, `CHANGELOG.md`, and the pin references atomically.
3. **Update CHANGELOG.md** — move `[Unreleased]` items to the new version section.
4. **Run `just verify`** — must pass with zero errors.
5. **Push + tag** — `git push && git push --tags`.
6. **Move the floating tag** — move `v1` to point to the new tag:
   ```bash
   git tag -f v1 <new-tag>
   git push origin v1 --force
   ```
7. **Create GitHub Release** — from the new tag; attach release notes from `CHANGELOG.md`.

## Version Scheme

`zenzic-action` uses semver (`MAJOR.MINOR.PATCH`):

- **PATCH**: wrapper script fixes, documentation, CI changes.
- **MINOR**: new action inputs/outputs, core pin update (backward compatible).
- **MAJOR**: breaking changes to action inputs or output schema.

## Core Pin Policy

The `version` input default in `action.yml` always pins to the latest stable Zenzic core
release. Pin updates are coordinated with the core release cycle — never auto-update.

## Supported Versions

| Action version | Support status |
|---|---|
| `v1` (current) | ✅ All fixes |
| `< v1` | ❌ End of life |
