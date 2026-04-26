#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
#
# bump-version.sh — Update the Zenzic version pinned as default in action.yml.
#
# Usage:
#   bash scripts/bump-version.sh <version>
#   just bump <version>
#
# What it updates:
#   action.yml  — the 'version' input default (the Zenzic CLI version to install)
#   README.md   — YAML code block example, stability note, and inputs table default
#
# The action's own semver (package.json "version") follows an independent
# release cycle and is not modified by this script.
#
# Example:
#   just bump 0.7.1
#   → action.yml: default: "0.7.0" → default: "0.7.1"
set -euo pipefail

VERSION="${1:?Usage: bump-version.sh <version>}"

# Validate version format (X.Y.Z or X.Y.Z-suffix)
if ! echo "${VERSION}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
    echo "Error: invalid version '${VERSION}' — expected format: X.Y.Z or X.Y.Z-suffix" >&2
    exit 1
fi

ACTION_YML="action.yml"

if [[ ! -f "${ACTION_YML}" ]]; then
    echo "Error: ${ACTION_YML} not found. Run from the repo root." >&2
    exit 1
fi

# Replace the version input default line
OLD_DEFAULT=$(grep -E '^\s+default: "[0-9]+\.[0-9]+\.[0-9]' "${ACTION_YML}" | head -1 | tr -d ' ')
sed -i "s/    default: \"[0-9][0-9a-zA-Z.-]*\"/    default: \"${VERSION}\"/" "${ACTION_YML}"

echo "✓ ${ACTION_YML}: version input default → ${VERSION}"
echo "  (was: ${OLD_DEFAULT})"

# Update all version references in README.md
README="README.md"
if [[ ! -f "${README}" ]]; then
    echo "Warning: ${README} not found — skipping README updates" >&2
else
    VERSION="${VERSION}" python3 - << 'PYEOF'
import re, os

version = os.environ["VERSION"]
content = open("README.md").read()

# YAML code block: version: "0.7.0"       # pin to a stable release
content = re.sub(
    r'(version: ")[0-9][0-9a-zA-Z.-]+(")(\s+# pin)',
    rf'\g<1>{version}\2\3',
    content,
)
# Stability note backtick: `version: "0.7.0"` is the default
content = re.sub(
    r'(`version: ")[0-9][0-9a-zA-Z.-]+("` is the default)',
    rf'\g<1>{version}\2',
    content,
)
# Inputs table default column: | `version` | `0.7.0` |
content = re.sub(
    r'(\| `version` \| )`[0-9][0-9a-zA-Z.-]+`',
    rf'\g<1>`{version}`',
    content,
)

open("README.md", "w").write(content)
print(f"✓ README.md: 3 version references → {version}")
PYEOF
fi
