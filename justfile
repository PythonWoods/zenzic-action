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
    # Permanent exclusion: contributor-covenant.org is a flaky third-party URL.
    GUARD=(
      --exclude-url "https://www.contributor-covenant.org/version/2/1/code_of_conduct.html"
    )
    uvx zenzic@v0.7.0 check all --strict "${GUARD[@]}" {{args}}

# Test suite (action-level checks via nox)
test:
    uvx nox -s tests

# Fast linter pass: run all pre-commit hooks without the full test suite.
lint:
    uvx pre-commit run --all-files

# Full verification gate (4-Gates Standard)
verify: _check-hooks check test

_check-hooks:
    #!/usr/bin/env bash
    if [ ! -f .git/hooks/pre-push ]; then
        echo -e "\033[33m⚠️  WARNING: Pre-push hook is not installed.\033[0m"
        echo "Without it, you might accidentally push broken code to GitHub and fail the remote CI."
        echo "👉 Fix it by running: uvx pre-commit install -t pre-push"
        echo ""
    fi

# Clean generated artefacts
clean:
    rm -rf .nox/
