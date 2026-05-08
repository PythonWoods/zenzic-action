# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0

set shell := ["bash", "-c"]

# just — developer workflow for zenzic-action (Hardcoded Stable).
# Use `just --list` to see available commands.

# Release orchestration: explicit, transparent, and lockfile-first.
release part:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ part }}" in
        patch|minor|major) ;;
        *) echo "Invalid part '{{ part }}'. Use patch|minor|major"; exit 2 ;;
    esac
    uvx --from "bump-my-version==1.2.6" bump-my-version bump {{ part }}
    if [ -f package-lock.json ]; then
        npm ci
    fi
    version="$(uvx --from "bump-my-version==1.2.6" bump-my-version show current_version)"
    if git rev-parse "v${version}" >/dev/null 2>&1; then
        echo "Tag v${version} already exists. Aborting."
        exit 3
    fi
    git add -u
    git commit -m "release: bump version to ${version}"
    git tag -a "v${version}" -m "Release v${version}"

# Show the current project version
version:
    @uvx --from "bump-my-version==1.2.6" bump-my-version show current_version

# Simulate a release bump without modifying any files
# Usage: just release-dry patch|minor|major
release-dry part:
    uvx --from "bump-my-version==1.2.6" bump-my-version bump {{part}} --dry-run --allow-dirty --verbose

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
