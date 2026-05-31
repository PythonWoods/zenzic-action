<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD033 MD041 MD060 -->

<p align="center">
  <a href="https://github.com/PythonWoods/zenzic-action">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="assets/zenzic-wordmark-action-dark.svg">
      <img alt="Zenzic / action" src="assets/zenzic-wordmark-action.svg" width="350">
    </picture>
  </a>
</p>

<p align="center">The deterministic enforcement point for documentation integrity in CI. Exit codes are contractual — exits 2 and 3 survive <code>fail-on-error: false</code>.</p>

<p align="center">
  <a href="https://github.com/PythonWoods/zenzic-action/actions/workflows/self-check.yml"><img alt="ci-status" src="https://img.shields.io/github/actions/workflow/status/PythonWoods/zenzic-action/self-check.yml?branch=main&label=ci&style=flat-square"></a>
  <!-- zenzic:audit-badge -->
  <img src="https://img.shields.io/badge/%F0%9F%9B%A1%EF%B8%8F_zenzic--audit-passing-22c55e?style=flat-square" alt="zenzic-audit">
  <!-- zenzic:score-badge -->
  <img src="https://img.shields.io/badge/%F0%9F%9B%A1%EF%B8%8F_zenzic--score-100_%2F_100-4f46e5?style=flat-square" alt="zenzic-score">

  <a href="https://github.com/PythonWoods/zenzic-action/releases"><img alt="action version" src="https://img.shields.io/github/v/release/PythonWoods/zenzic-action?label=action&color=4f46e5&style=flat-square"></a>
  <a href="https://pypi.org/project/zenzic"><img alt="zenzic on PyPI" src="https://img.shields.io/pypi/v/zenzic?label=zenzic&color=0284c7&style=flat-square"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-Apache--2.0-0d9488?style=flat-square"></a>
  <a href="https://reuse.software/"><img alt="REUSE 3.x compliant" src="https://img.shields.io/badge/REUSE-3.x%20compliant-0d9488?style=flat-square"></a>
</p>

---

Run Zenzic checks in CI and surface results directly in GitHub Code Scanning, Pull Request annotations, and the Security tab — without reading logs.

**Exit code contract.** The wrapper propagates Zenzic's exit codes without remapping. Exit 1 (quality) obeys `fail-on-error`. Exit 2 (credential) and exit 3 (path traversal) terminate the job regardless of `fail-on-error: false` or `--exit-zero` — security findings are never suppressed at the enforcement boundary.

## Core Features

| Feature | Description |
|---|---|
| Zero-setup install | `uvx zenzic` — no Python toolchain required on the runner |
| SARIF output | Findings feed directly into GitHub Code Scanning |
| Exit Code Contract | Security incidents (exit 2/3) are never suppressed by `fail-on-error` |
| Sovereign Audit mode | `audit: "true"` bypasses all suppressions — surfaces the true documentation state |
| SARIF integrity check | Validates JSON before upload; emits `::warning` if truncated by SIGKILL |
| PR annotations | Inline findings on the diff, colour-coded by severity |
| Version pinning | Pin to an exact release for deterministic, reproducible CI gates |
| **Clean prose** | `[governance.directory_policies]` in `.zenzic.toml` grants zero-debt exemptions to path patterns |

## Quick Start

The minimal configuration — zero Python setup, SARIF to Code Scanning in one step:

```yaml title=".github/workflows/docs.yml"
- uses: actions/checkout@v6

- name: Run Zenzic Documentation Quality Gate
  uses: PythonWoods/zenzic-action@v1
  with:
    version: "0.8.1"
    format: sarif
    upload-sarif: "true"
  permissions:
    contents: read
    security-events: write
```

Place a `.zenzic.toml` at the root of your repository and the action picks it up automatically — no `config-file` input required. Run `zenzic init` once to scaffold a config if your docs live outside the default `docs/` folder.

For advanced configuration (Configuration Discovery, Sovereign Override, Quality Gate scoring, nightly audit), see the [Zenzic Action docs](https://zenzic.dev/docs/reference/zenzic-action).

---

## Inputs

| Input | Default | Description |
|---|---|---|
| `version` | `0.8.1` | Zenzic version to install. Pin to a specific release for reproducible CI. Set `latest` for continuous evaluation. |
| `format` | `sarif` | Output format: `text`, `json`, or `sarif`. |
| `sarif-file` | `zenzic-results.sarif` | SARIF output path (when `format: sarif`). Must be a **relative** path inside the workspace. |
| `upload-sarif` | `true` | Upload SARIF to GitHub Code Scanning. |
| `strict` | `false` | Treat warnings as errors. |
| `fail-on-error` | `true` | Fail the workflow step on findings. |
| `config-file` | *(auto)* | Optional path to a config file. Auto-discovers `.zenzic.toml` → `.github/.zenzic.toml` when omitted. |
| `audit` | `false` | Sovereign audit mode: bypass all `zenzic:ignore` comments and `per_file_ignores`. Reveals the true unfiltered documentation state. Recommended for nightly builds and security review workflows. |
| `diff-base` | *(snapshot)* | Path to a JSON baseline file for `zenzic diff`. Use an artifact from the `main` branch to block PRs that increase technical debt. Falls back to `.zenzic-score.json` when omitted. |
| `guard-scan` | `false` | Run `zenzic guard scan` as a Defense-in-Depth step **before** the main quality gate. Catches hardcoded credentials and forbidden patterns that bypassed pre-commit hooks. Failure is always fatal — not governed by `fail-on-error`. |

## Outputs

| Output | Description |
|---|---|
| `sarif-file` | Path to the generated SARIF file. |
| `findings-count` | Total number of findings. |
| `score` | Documentation Quality Score (0–100). Available when `format: json` or when `diff-base` is set. |
| `suppression-debt-pts` | Technical Debt points deducted from the score due to active suppressions. `0` when no suppressions are active. |
| `cap-exceeded` | `"true"` when the suppression CAP was exceeded and blocked the build; `"false"` otherwise. |

## Advanced Workflows

### Debt Regression Blocking

Block pull requests that increase documentation debt. Save a baseline from `main` as a workflow artifact; the quality-gate job downloads it and fails if `zenzic diff` reports a score drop.

```yaml
jobs:
  baseline:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Save score baseline
        uses: PythonWoods/zenzic-action@v1
        with:
          format: json
          save: "true"
      - uses: actions/upload-artifact@v4
        with:
          name: zenzic-baseline
          path: .zenzic-score.json

  quality-gate:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: zenzic-baseline
      - name: Block debt regression
        uses: PythonWoods/zenzic-action@v1
        with:
          format: json
          diff-base: .zenzic-score.json
```

### Sovereign Nightly Audit

Run a full unfiltered audit nightly to reveal the true documentation state — bypassing all `zenzic:ignore` comments and `per_file_ignores`. Findings that are suppressed in day-to-day CI are visible here.

```yaml
on:
  schedule:
    - cron: "0 3 * * *"   # 03:00 UTC daily

jobs:
  sovereign-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Sovereign audit (no suppressions)
        uses: PythonWoods/zenzic-action@v1
        with:
          audit: "true"
          format: sarif
          upload-sarif: "true"
```

### Using Action Outputs

Capture `score`, `suppression-debt-pts`, and `cap-exceeded` from the action for conditional logic or downstream reporting.

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Zenzic quality gate
    id: zenzic
    uses: PythonWoods/zenzic-action@v1
    with:
      format: json
      fail-on-error: "false"

  - name: Report score
    run: |
      echo "Score: ${{ steps.zenzic.outputs.score }}/100"
      echo "Suppression debt: ${{ steps.zenzic.outputs.suppression-debt-pts }} pts"

  - name: Fail if suppression CAP exceeded
    if: steps.zenzic.outputs.cap-exceeded == 'true'
    run: |
      echo "::error::Suppression CAP exceeded — build blocked."
      exit 1
```

---

## Exit Codes

| Code | Meaning | Suppressible? |
|:---:|---|:---:|
| `0` | All checks passed | — |
| `1` | Documentation findings (broken links, orphans, suppression CAP) | Yes (`fail-on-error: "false"`) |
| **`2`** | **Credential detected (Z201)** | **Never** |
| **`3`** | **Path traversal detected (Z202/Z203)** | **Never** |

---

For advanced governance (Scoring & Debt, Sovereign Audit, Quality Gate PR blocking), see the
[Zenzic Action docs](https://zenzic.dev/docs/reference/zenzic-action).

For security architecture internals (exit code contract, Root-First discovery, SARIF integrity guard),
see the [Engineering Ledger](https://zenzic.dev/developers/explanation/engineering-ledger).

## License

Apache-2.0 — see [LICENSE](LICENSE).
