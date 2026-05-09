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

# Show the current action version
version:
    @uvx --from "bump-my-version==1.2.6" bump-my-version show current_version

# Show the pinned Zenzic Core version used by this action
core-version:
    @perl -ne 'if (/default: "([^"]+)" # x-zenzic-core-pin/) { print "$1\n"; $found=1 } END { exit($found ? 0 : 1) }' action.yml

# Show both the action version and the pinned Zenzic Core version
versions:
    @echo "action:      $(uvx --from "bump-my-version==1.2.6" bump-my-version show current_version)"
    @echo "zenzic-core: $(perl -ne 'if (/default: "([^"]+)" # x-zenzic-core-pin/) { print "$1\n"; $found=1 } END { exit($found ? 0 : 1) }' action.yml)"

# Realign the Zenzic Core pin in action.yml using the anchored marker
# Usage: just pin-core 0.7.1
pin-core version:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! "{{version}}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version '{{version}}'. Use MAJOR.MINOR.PATCH"
        exit 2
    fi
    if [ -n "$(git status --porcelain)" ]; then
        echo "Working tree is not clean. Commit or stash changes before pin-core."
        exit 3
    fi
    echo "Aligning Zenzic Core pin to {{version}}..."
    perl -i -pe 's/default: "[^"]+"\s*# x-zenzic-core-pin/default: "{{version}}" # x-zenzic-core-pin/' action.yml
    perl -i -pe 's/zenzic\@v[0-9\.]+[a-z0-9]*/zenzic\@v{{version}}/' noxfile.py
    git add action.yml noxfile.py
    git commit -m "chore(deps): pin zenzic core to {{version}}"

# Simulate a release bump without modifying any files
# Usage: just release-dry patch|minor|major [--short]
release-dry part *args:
    #!/usr/bin/env bash
    set -euo pipefail
    _short=false
    for _arg in {{args}}; do [[ "$_arg" == "--short" ]] && _short=true; done
    if $_short; then
        uvx --from "bump-my-version==1.2.6" bump-my-version bump {{part}} --dry-run --allow-dirty --verbose 2>&1 \
            | grep -E 'current version|New version will be|Dry run'
    else
        uvx --from "bump-my-version==1.2.6" bump-my-version bump {{part}} --dry-run --allow-dirty --verbose
    fi

# Simulate a Zenzic Core pin realignment without modifying files
# Usage: just core-align-dry 0.7.1
core-align-dry core_version:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! "{{core_version}}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid core version '{{core_version}}'. Use MAJOR.MINOR.PATCH"
        exit 2
    fi
    current="$(just core-version)"
    echo "Current core pin: ${current}"
    echo "Target core pin:  {{core_version}}"
    echo "Would update anchored line in action.yml"

# Realign action files to a specific released Zenzic Core version
# Usage: just core-align 0.7.1
core-align core_version:
    just pin-core {{core_version}}

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
    CORE_PATH="${ZENZIC_PROJECT_PATH:-../zenzic}"
        if [ -d "$CORE_PATH" ]; then
        echo "🛡️  [Zenzic Sentinel] Local core detected. Using: $CORE_PATH"
        uv run --project "$CORE_PATH" zenzic check all --strict "${GUARD[@]}" {{args}}
    else
        echo "🛡️  [Zenzic Sentinel] Local core not found. Using published PyPI release..."
        uvx zenzic@0.7.1 check all --strict "${GUARD[@]}" {{args}}
    fi

# Test suite (action-level checks via nox)
test:
    uvx nox -s tests

# Fast linter pass: run all pre-commit hooks without the full test suite.
lint:
    uvx pre-commit run --all-files

# Full verification gate (4-Gates Standard)
verify: _check-hooks lint release-contracts test

_check-hooks:
    #!/usr/bin/env bash
    if [ ! -f .git/hooks/pre-push ]; then
        echo -e "\033[33m⚠️  WARNING: Pre-push hook is not installed.\033[0m"
        echo "Without it, you might accidentally push broken code to GitHub and fail the remote CI."
        echo "👉 Fix it by running: uvx pre-commit install -t pre-push"
        echo ""
    fi

# Enforce release contracts and core-pin anchor integrity.
release-contracts:
    #!/usr/bin/env bash
    set -euo pipefail
    grep -qE '^version:' justfile
    grep -qE '^core-version:' justfile
    grep -qE '^pin-core version:' justfile
    grep -qE '^release part:' justfile
    grep -qE '^release-dry part' justfile
    grep -q -- '--dry-run --allow-dirty --verbose' justfile
    grep -q 'x-zenzic-core-pin' action.yml
    if sed -n '/^release part:/,/^[^[:space:]].*:/p' justfile | tail -n +2 | grep -q -- '--allow-dirty'; then
        echo "release-contracts failed: release part must not use --allow-dirty"
        exit 1
    fi

# Clean generated artefacts
clean:
    rm -rf .nox/
