# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0

set shell := ["bash", "-c"]

# just — developer workflow for zenzic-action (Hardcoded Stable).
# Use `just --list` to see available commands.

# Bump the Zenzic version pinned as default in action.yml.
# Usage:  just bump 0.7.1
bump version:
    @bash scripts/bump-version.sh "{{version}}"

# Check REUSE/SPDX licence compliance
reuse:
    uvx reuse lint

# Run the Zenzic Sentinel quality gate on action documentation
# Uses the stable v0.7.0 release for maximum reliability.
# ZRT-010 — Sovereign Parity: Pre-Launch Guard inlined; local == CI.
# Pass extra flags directly: just check --no-external
check *args:
    #!/usr/bin/env bash
    set -euo pipefail
    # Pre-Launch Guard — remove after GA deploy when all URLs resolve
    GUARD=(
      --exclude-url "https://zenzic.dev/blog/"
      --exclude-url "https://zenzic.dev/docs/"
      --exclude-url "https://zenzic.dev/developers/"
      --exclude-url "https://zenzic.dev/it/developers/"
      --exclude-url "https://github.com/PythonWoods/zenzic/releases/tag/v0.7.0"
    )
    uvx zenzic@v0.7.0 check all --strict "${GUARD[@]}" {{args}}

# Test suite (action-level checks via nox)
test:
    uvx nox -s tests

# Full CI-equivalent pipeline (delegates to nox)
preflight:
    uvx pre-commit run --all-files

# Fast linter pass: run all pre-commit hooks without the full test suite.
lint:
    uvx pre-commit run --all-files

# Full verification gate (4-Gates Standard)
verify: check preflight test

# Clean generated artefacts
clean:
    rm -rf .nox/
