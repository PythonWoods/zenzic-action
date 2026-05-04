<!--
SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
SPDX-License-Identifier: Apache-2.0
-->

# Contributing to zenzic-action

Thank you for contributing to the official GitHub Action for Zenzic.

## Core Dependency

A differenza della documentazione, `zenzic-action` è vincolata alle release stabili del core. Per testare l'azione contro versioni non rilasciate del core, è necessario modificare temporaneamente il comando `uvx` nel workflow di test.

This action relies on the published Zenzic CLI on PyPI. It acts as a stable wrapper to distribute Zenzic inside GitHub Actions securely.

## Local Verification

Use `just` to run the self-tests before opening a PR:

```bash
just verify
```

This will run `pre-commit` checks and the Action's integration tests via Nox.
