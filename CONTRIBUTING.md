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
