# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0

# just — developer workflow for zenzic-action.
# Use `just --list` to see available commands.

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
    uvx zenzic check all

# Full CI-equivalent pipeline (delegates to nox)
preflight:
    uv run nox -s preflight

# Clean generated artefacts
clean:
    rm -rf .nox/
