<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Release Procedure — zenzic-action

## Release Metadata

| Field   | Value      |
| :------ | :--------- |
| Version | v1.0.1     |
| Date    | 2026-05-14 |
| Status  | Stable     |

## Release Checklist

Before tagging, every item must be green:

- [ ] `action.yml` — `default:` pin updated to the latest Zenzic core version
- [ ] `package.json` version bumped
- [ ] `CHANGELOG.md` — `[Unreleased]` section moved to the new version heading
- [ ] `just verify` — exits 0
- [ ] `zenzic check .` — zero findings

## Bump & Publish

```bash
# Bumps package.json, CHANGELOG.md, and action.yml pin atomically:
just bump <version>    # e.g. just bump 1.1.0

git push && git push --tags

# Move the floating v1 tag to the new release:
git tag -f v1 <new-tag>
git push origin v1 --force
```

Distribution target: **GitHub Actions Marketplace** — `uses: PythonWoods/zenzic-action@v1`.

## Version Scheme

| Increment | Trigger                                      |
| :-------- | :------------------------------------------- |
| PATCH     | Wrapper script fixes, documentation, CI      |
| MINOR     | New inputs/outputs, core pin update          |
| MAJOR     | Breaking changes to inputs or output schema  |

## Core Pin Policy

`action.yml` always pins to the latest stable Zenzic core release.
Pin updates are coordinated with the core release cycle — never auto-update.

## Changelog Reference

For a detailed list of changes, see [CHANGELOG.md](./CHANGELOG.md).
