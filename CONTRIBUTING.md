<!--
SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
SPDX-License-Identifier: Apache-2.0
-->

# Contributing to zenzic-action

Thank you for contributing to the official GitHub Action for Zenzic.

## Core Dependency

A differenza della documentazione, `zenzic-action` è vincolata alle release stabili del core. Per testare l'azione contro versioni non rilasciate del core, è necessario modificare temporaneamente il comando `uvx` nel workflow di test.

This action relies on the published Zenzic CLI on PyPI. It acts as a stable wrapper to distribute Zenzic inside GitHub Actions securely.

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
