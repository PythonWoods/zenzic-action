# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0

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
check:
    uvx zenzic@v0.7.0 check all --strict

# Test suite (action-level checks via nox)
test:
    uvx nox -s tests

# Full CI-equivalent pipeline (delegates to nox)
preflight:
    uvx pre-commit run --all-files

# Full verification gate (4-Gates Standard)
verify: check preflight test

# Clean generated artefacts
clean:
    rm -rf .nox/
