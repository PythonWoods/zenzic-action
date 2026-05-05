<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/zenzic-wordmark-action-dark.svg">
    <img alt="Zenzic / action" src="assets/zenzic-wordmark-action.svg" width="350">
  </picture>
</p>

<p align="center">The deterministic enforcement point for documentation integrity in CI. Exit codes are contractual — exits 2 and 3 survive <code>fail-on-error: false</code>.</p>

<p align="center">
  <a href="https://github.com/PythonWoods/zenzic-action/releases"><img alt="action version" src="https://img.shields.io/github/v/release/PythonWoods/zenzic-action?label=action&color=4f46e5"></a>
  <a href="https://pypi.org/project/zenzic"><img alt="zenzic on PyPI" src="https://img.shields.io/pypi/v/zenzic?label=zenzic&color=0284c7"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-Apache--2.0-blue"></a>
  <a href="https://zenzic.dev/developers/explanation/adr-vault"><img alt="4-Gates: Sentinel Seal" src="https://img.shields.io/badge/4--Gates-Sentinel%20Seal-10b981?style=flat-square"></a>
  <a href="https://reuse.software/"><img alt="REUSE 3.x compliant" src="https://img.shields.io/badge/REUSE-3.x%20compliant-0d9488?style=flat-square"></a>
</p>

---

Run Zenzic checks in CI and surface results directly in GitHub Code Scanning, Pull Request annotations, and the Security tab — without reading logs.

**Exit code contract.** The wrapper propagates Zenzic's exit codes without remapping. Exit 1 (quality) obeys `fail-on-error`. Exit 2 (credential) and exit 3 (path traversal) terminate the job regardless of `fail-on-error: false` or `--exit-zero` — security findings are never suppressed at the enforcement boundary.

<p align="center">
  <img alt="GitHub Code Scanning showing Zenzic findings" src="assets/sarif-showcase.svg" width="780">
</p>

## Core Features

| Feature | Description |
|---|---|
| Zero-setup install | `uvx zenzic` — no Python toolchain required on the runner |
| SARIF output | Findings feed directly into GitHub Code Scanning |
| Exit Code Contract | Security incidents (exit 2/3) are never suppressed by `fail-on-error` |
| SARIF integrity check | Validates JSON before upload; emits `::warning` if truncated by SIGKILL |
| PR annotations | Inline findings on the diff, colour-coded by severity |
| Version pinning | Pin to an exact release for deterministic, reproducible CI gates |

## Usage

```yaml
- name: Run Zenzic Documentation Quality Gate
  uses: PythonWoods/zenzic-action@v1
  with:
    format: sarif
    upload-sarif: "true"
```

Add `permissions: security-events: write` to the job so the SARIF upload succeeds.

Full example:

```yaml
jobs:
  docs:
    name: Documentation Quality
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v6

      - name: Run Zenzic
        uses: PythonWoods/zenzic-action@v1
        with:
          version: "0.7.0"       # pin to a stable release
          format: sarif           # emit SARIF for Code Scanning
          upload-sarif: "true"    # post results to the Security tab
          strict: "false"
          fail-on-error: "true"
```

> **Docs directory:** Zenzic reads its configuration from `zenzic.toml` at the repository root.
> Run `zenzic init` once to scaffold a config if your docs live outside the default `docs/` folder.

> **Stability:** `version: "0.7.0"` is the default. For the latest features as they ship, you can set `version: latest`, but production pipelines should always pin to a specific release for deterministic, reproducible runs.

## Inputs

| Input | Default | Description |
|---|---|---|
| `version` | `0.7.0` | Zenzic version to install. Pinned to a specific release for deterministic, reproducible runs. Set `latest` for continuous evaluation of new features. |
| `format` | `sarif` | Output format: `text`, `json`, or `sarif`. |
| `sarif-file` | `zenzic-results.sarif` | SARIF output path (when `format: sarif`). Must be a **relative** path inside the workspace. Absolute paths and `..` traversal sequences are rejected. |
| `upload-sarif` | `true` | Upload SARIF to GitHub Code Scanning. |
| `strict` | `false` | Treat warnings as errors. |
| `fail-on-error` | `true` | Fail the workflow step on findings. |

## Outputs

| Output | Description |
|---|---|
| `sarif-file` | Path to the generated SARIF file. |
| `findings-count` | Total number of findings. |

## SARIF & GitHub Code Scanning

When `format: sarif` and `upload-sarif: true`, Zenzic findings appear:

- In the **Security → Code Scanning** tab of the repository.
- As **inline annotations** on Pull Request diffs.
- Colour-coded by severity: errors in red, warnings in yellow, security findings with a CVSS-style score (`9.5` for credential breaches, `9.0` for path-traversal incidents).

No additional configuration needed — the action handles the upload via `github/codeql-action/upload-sarif`.

## How it works

1. Installs `uv` with cache enabled.
2. Runs `uvx "zenzic==<version>"` (or `uvx zenzic` for latest) — a single isolated invocation, no pre-install step.
3. Writes the SARIF report to `sarif-file` (stdout only; stderr streams to the step log).
4. Validates SARIF JSON integrity — emits a `::warning` annotation if the file is truncated (e.g. due to SIGKILL).
5. Uploads via `github/codeql-action/upload-sarif`.

## Supported Environments

| Component | Minimum | Recommended | Notes |
|:--|:--|:--|:--|
| **GitHub-hosted runner** | `ubuntu-22.04` | `ubuntu-latest` | macOS and Windows runners are also supported |
| **Self-hosted runner** | Any OS with `bash` ≥ 5 and `python3` ≥ 3.11 | — | `uv` is installed by the action; no pre-install needed |
| **Node.js** | 24 | 24 | Required by `github/codeql-action/upload-sarif@v4` |
| **`astral-sh/setup-uv`** | v8 | v8 | Earlier versions lack full cross-platform cache support |
| **`github/codeql-action`** | v4 | v4 | v3 deprecated; v2 reached end-of-life March 2024 |
| **`actions/checkout`** | v6 | v6 | Must run before this action |

> **Self-hosted runners:** ensure `python3` (3.11+) and `bash` (5+) are available in `PATH`.
> `uv` is installed by the action via `astral-sh/setup-uv` — no pre-installed Python toolchain required.

## Ecosystem

| Component | Repository / URL | Description |
|---|---|---|
| **Zenzic CLI** | [PythonWoods/zenzic](https://github.com/PythonWoods/zenzic) | Core linter — install with `pip install zenzic` or run via `uvx zenzic` |
| **Documentation** | [zenzic.dev](https://zenzic.dev) | Configuration reference, rule catalogue, and how-to guides |
| **Brand System** | [zenzic.dev/assets/brand/zenzic-brand-system.html](https://zenzic.dev/assets/brand/zenzic-brand-system.html) | Visual identity, badges, and SVG assets |
| **zenzic-action** | [PythonWoods/zenzic-action](https://github.com/PythonWoods/zenzic-action) | This repository |

---

## 📖 Documentation Map — Quartz Promise

The Zenzic documentation lives across **two separate Docusaurus instances** under
[zenzic.dev](https://zenzic.dev) — the user area and the developer area never
share a sidebar or a search index.

```text
zenzic.dev/
├── docs/           → User Area    — install, configure, CI/CD, finding codes
├── developers/     → Dev Area     — plugins, adapters, ADRs, tech debt ledger
├── blog/           → Release notes & engineering post-mortems
└── community/      → Brand kit, FAQs, governance
```

The split is enforced by [ADR 011: Cross-Instance Allowlist](https://zenzic.dev/developers/explanation/adr-cross-instance-allowlist) — every cross-boundary link is a documented contract, never a silent suppression.

| You are a... | Start here |
| :--- | :--- |
| 👤 Action user (CI integrator) | [CI/CD Guide](https://zenzic.dev/docs/how-to/configure-ci-cd/) |
| 🔧 Action contributor | [Developer Portal](https://zenzic.dev/developers/) · [ADR Vault](https://zenzic.dev/developers/explanation/adr-vault) |
| 🛡️ Security reviewer | [Engineering Ledger](https://zenzic.dev/developers/explanation/engineering-ledger) · [SECURITY.md](SECURITY.md) |

---

## License

Apache-2.0 — see [LICENSE](LICENSE).
