<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Release Procedure — zenzic-action

## Release Metadata

| Field   | Value      |
| :------ | :--------- |
| Version | v1.1.0     |
| Date    | 2026-06-08 |
| Status  | Stable     |

## Release Checklist

Before tagging, every item must be green:

- [ ] `action.yml` — `default:` pin updated to the latest Zenzic core version (`0.9.0`)
- [ ] `package.json` version bumped to `1.1.0`
- [ ] `CHANGELOG.md` — `[Unreleased]` section promoted to `[1.1.0] - 2026-05-31`
- [ ] Update SECURITY.md support table (add v1.1.0, demote previous to Critical/EOL).
- [ ] `just verify` — exits 0
- [ ] `zenzic check .` — zero findings
- [ ] `guard-scan` input documented in README.md
- [ ] `cap-exceeded` output wired in wrapper and documented

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

## Changelog Reference

For a detailed list of changes, see [CHANGELOG.md](./CHANGELOG.md).
