<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Release Procedure — zenzic-action

## Release Metadata

| Field   | Value      |
| :------ | :--------- |
| Version | v2.8.0 |
| Date    | 2026-07-12 |
| Status  | Stable     |

## Release Checklist

Before tagging, every item must be green:

- [ ] `action.yml` — `default:` pin updated to the latest Zenzic core version (`0.22.1`)
- [ ] `package.json` version bumped to `2.8.0`
- [ ] `pyproject.toml` — synchronized with core pin (`zenzic>=0.22.1`)
- [ ] `just versions` — returns `✅ Ecosystem alignment verified.`
- [ ] `just verify` — exits 0
- [ ] `zenzic check .` — zero findings (DQS 100/100)

## Bump & Publish

```bash
# 1. Merge the PR and switch to main
git checkout main
git pull origin main

# 2. Bump version and update changelog
just release <patch|minor|major>

# 3. Create the release tag and push
git tag v2.8.0
git push && git push --tags

# 4. Move the floating v2 tag to the new release:
git tag -fa v2 v2.8.0^{} -m "release: v2.8.0"
git push origin v2 --force

# Verification (Atomic Parity Check):
git rev-parse v2^{} v2.8.0^{}
# SUCCESS: Both hashes must be identical.
```

Distribution target: **GitHub Actions Marketplace** — `uses: PythonWoods/zenzic-action@v2`.

## Version Scheme

| Increment | Trigger                                      |
| :-------- | :------------------------------------------- |
| PATCH     | Wrapper script fixes, documentation, CI      |
| MINOR     | New inputs/outputs, core pin update          |
| MAJOR     | Breaking changes to inputs or output schema  |

## Changelog Reference

For a detailed list of changes, see [CHANGELOG.md](./CHANGELOG.md).
