<!--
SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
SPDX-License-Identifier: Apache-2.0
-->

# Contributing to zenzic-action

Thank you for contributing to the official GitHub Action for Zenzic.

## Core Dependency

Runtime distribution for downstream users remains pinned to published Zenzic
releases. Repository quality gates (self-check, just, nox), however, use the
shared sovereign local-core model.

Branch parity resolution in CI follows this precedence:

1. Explicit override via repository variable `ZENZIC_CORE_REF`.
2. Same-name branch parity (`github.base_ref` or `github.ref_name`).
3. Fallback to `main` if the target branch does not exist in core.

Use `ZENZIC_CORE_REF` when zenzic-action branch naming differs from core
repositories (for example, action release branch vs core release branch).

Override governance is mandatory (fail-closed): when `ZENZIC_CORE_REF` is set,
the following repository variables are required:

1. `ZENZIC_CORE_REF_TICKET` (change/audit ticket)
2. `ZENZIC_CORE_REF_REASON` (explicit justification)
3. `ZENZIC_CORE_REF_APPROVER` (owner who approved)
4. `ZENZIC_CORE_REF_EXPIRES_ON` (UTC date in `YYYY-MM-DD`)

If metadata is missing, malformed, expired, or the branch does not exist in
core, CI stops with an explicit error.

## First-Time Setup

Install the pre-commit hooks (run once after cloning):

```bash
uvx pre-commit install               # commit-stage: hygiene + zenzic self-check
uvx pre-commit install -t pre-push   # pre-push: 🛡️ Final Guard runs `just verify`
```

## Local Verification

Use `just` to run the self-tests before opening a PR:

```bash
just lint      # fast pass: pre-commit hooks only
just verify    # full gate: pre-commit + Zenzic check + integration tests
```

Both must pass with zero errors before you open or update a PR.

### CI/CD & Workflow
- **Draft PRs:** We run CI exclusively on `main` and Pull Requests to save resources. Open a **Draft PR** early to get continuous CI feedback on your branch.
- **Hooks:** Use `pre-commit` for local mutations. Do not use `post-commit`.
- **Full Guide:** Read the complete workflow in our [Developer Documentation](https://zenzic.dev/developers/how-to/contribute/pull-requests).

## Maintainer Only: Workflow Hardening

### Immutable Pre-Commit Hooks (ADR-089)

All `rev:` keys in `.pre-commit-config.yaml` must point to an **immutable commit
hash pin**, never to a semantic tag (`v1.2.3`). Git tags are mutable: an upstream
maintainer (or an attacker) can move a tag silently, poisoning the local
Gate 2 without any diff in this repository.

This is an **internal CI policy for the zenzic-action project**, not a public
Zenzic linter rule. Enforcement: `just check-pinning` (dependency of
`just verify`); violations raise `[ADR-089] FATAL` at pre-push.

The local exposure window is smaller than the GHA one because `pre-commit`
freezes hook repos in `~/.cache/pre-commit/` until the user runs `autoupdate`
or `clean`; GitHub Actions instead re-resolves the ref on every run. Pinning
is still mandatory locally for new-clone safety and parity with the remote
ADR-089 enforcement.

**Updating pinned hooks.** Never run plain `pre-commit autoupdate` — it
rewrites SHAs back to mutable tags. Always use:

```bash
uvx pre-commit autoupdate --freeze
```

This preserves the `# vX.Y.Z` annotation comment. Commit the diff and
re-verify with `just check-pinning`.
