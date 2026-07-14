<!--
SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
SPDX-License-Identifier: Apache-2.0
-->

# Security Policy — zenzic-action

## Scope

This policy covers **zenzic-action** — the official GitHub Action that runs
`zenzic check all` as a CI gate and uploads findings to GitHub Code Scanning via SARIF.

For vulnerabilities in the **Zenzic engine** (Python, credential scanner, path-traversal
protection), see the [core security policy](https://github.com/PythonWoods/zenzic/blob/main/SECURITY.md).

---

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Report privately via:

- **GitHub Security Advisories** (preferred): [github.com/PythonWoods/zenzic-action/security/advisories](https://github.com/PythonWoods/zenzic-action/security/advisories)
- **Email**: `dev@pythonwoods.dev` — subject line: `[SECURITY] zenzic-action — <brief description>`

Include a clear description of the vulnerability, steps to reproduce, potential impact,
and a suggested fix if available.

We will acknowledge your report within **72 hours** and aim to release a patch within
**14 days** of confirming the issue.

---

## In-Scope Areas

| Area | Description |
|------|-------------|
| **Exit code suppression** | Any method that prevents exit code `2` (credential scanner) or `3` (path traversal guard) from propagating — even via `fail-on-error: false` or any other input |
| **SARIF integrity bypass** | A condition under which a truncated or empty SARIF file is uploaded as a false-clean result |
| **Wrapper script injection** | A crafted action input that causes arbitrary shell code execution inside `zenzic-action-wrapper.sh` |
| **Secret exposure via outputs** | A scenario where credentials appear in `$GITHUB_OUTPUT` or workflow logs from the wrapper script |
| **Dependency CVE** | A known CVE in `astral-sh/setup-uv`, `actions/checkout`, or `github/codeql-action` that affects the action's security posture |

Out-of-scope: quality findings (`fail-on-error: false` suppression of exit 1), cosmetic
output formatting, documentation errors, or issues only reproducible with self-hosted runners
in non-standard configurations.

---

## Security Design Notes

`zenzic-action` is a **composite action** (no Docker, no compiled JS). The execution
surface is limited to `zenzic-action-wrapper.sh` — a bash script that:

- Calls `uvx zenzic check all` in an isolated environment via `astral-sh/setup-uv`.
- Writes outputs to `$GITHUB_OUTPUT` **before** any `exit` call (output-first semantics).
- Enforces the exit code contract unconditionally: exit 2 and 3 are **never suppressible**.
- Validates SARIF JSON integrity with a Python one-liner before upload.

**The action requires exactly two permissions** declared at the job level:

```yaml
permissions:
  contents: read        # checkout
  security-events: write  # upload-sarif to Code Scanning
```

No other permissions are required or granted. The `GITHUB_TOKEN` is never read
by the wrapper script — it is consumed exclusively by `github/codeql-action/upload-sarif`.

---

## Supported Versions

| Version | Support status |
|---------|----------------|
| `2.8.3` (current) | ✅ All security fixes |
| `< 2.8.3` | ❌ End of life — no support |

---

## Disclosure Policy

We follow a **coordinated disclosure** model. We ask that you allow up to 14 days for a
patch to be released before any public disclosure. Confirmed reporters will be credited in
the release changelog unless they prefer to remain anonymous.
