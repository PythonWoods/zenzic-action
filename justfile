# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0

# just — developer workflow for zenzic-action.
# Use `just --list` to see available commands.
zenzic_project := env_var_or_default("ZENZIC_PROJECT_PATH", "../zenzic")

# Bump the Zenzic version pinned as default in action.yml.
# Usage:  just bump 0.7.1
bump version:
    @bash scripts/bump-version.sh "{{version}}"

# Update the [CODE MAP] in copilot-instructions.md from action.yml and the wrapper script.
# Run after changing action.yml or zenzic-action-wrapper.sh.
map-update:
    uv run scripts/map_action.py

# Check REUSE/SPDX licence compliance
reuse:
    uvx reuse lint

# Run the Zenzic Sentinel quality gate on action documentation
check:
    uv run --project {{zenzic_project}} zenzic check all --strict

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
