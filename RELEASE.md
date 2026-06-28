<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Release Procedure — zenzic-action

## Release Metadata

| Field   | Value      |
| :------ | :--------- |
| Version | v2.3.2 |
| Date    | 2026-06-27 |
| Status  | Stable     |

## Release Checklist

Before tagging, every item must be green:

- [ ] `action.yml` — `default:` pin updated to the latest Zenzic core version (`0.18.0`)
- [ ] `package.json` version bumped to `2.3.2`
- [ ] `CHANGELOG.md` — `[Unreleased]` section promoted to `[2.3.2]`
- [ ] Update SECURITY.md support table (add v2.3.2, demote previous).
- [ ] `pyproject.toml` — synchronized with core pin (`zenzic>=0.18.0`)
- [ ] `just versions` — returns `✅ Ecosystem alignment verified.`
- [ ] `just verify` — exits 0
- [ ] `zenzic check .` — zero findings (DQS 100/100)

## Bump & Publish

```bash
# Bumps version and updates changelog:
just release <patch|minor|major>

git push && git push --tags

# Move the floating v2 tag to the new release:
git tag -fa v2 <new-tag-version> -m "release: <new-tag-version>"
git push origin v2 --force

# Verification (Atomic Parity Check):
git rev-parse v2^{} <new-tag-version>^{}
# SUCCESS: Both hashes must be identical.
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
