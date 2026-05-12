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
  <a href="https://zenzic.dev/developers/explanation/adr-vault"><img alt="4-Gates: Zenzic Audit Badge" src="https://img.shields.io/badge/4--Gates-Zenzic%20Audit%20Badge-10b981?style=flat-square"></a>
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

## Quick Start

The minimal configuration — zero Python setup, SARIF to Code Scanning in one step:

```yaml title=".github/workflows/docs.yml"
- uses: actions/checkout@v6

- name: Run Zenzic Documentation Quality Gate
  uses: PythonWoods/zenzic-action@v1
  with:
    version: "0.7.1"
    format: sarif
    upload-sarif: "true"
  permissions:
    contents: read
    security-events: write
```

Place a `zenzic.toml` at the root of your repository and the action picks it up automatically — no `config-file` input required.

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
          version: "0.7.1"       # pin to a stable release
          format: sarif           # emit SARIF for Code Scanning
          upload-sarif: "true"    # post results to the Security tab
          strict: "false"
          fail-on-error: "true"
```

> **Zero-Config Setup:** The action auto-discovers your Zenzic configuration automatically — no `config-file` input required. It searches in priority order: `zenzic.toml` in the repository root first, then `.github/zenzic.toml` as a fallback. This gives you identical behaviour between `zenzic check all` locally and in CI. To pin a specific file, set `config-file: path/to/zenzic.toml`.
> Run `zenzic init` once to scaffold a config if your docs live outside the default `docs/` folder.

> **Stability:** `version: "0.7.1"` is the default. For the latest features as they ship, you can set `version: latest`, but production pipelines should always pin to a specific release for deterministic, reproducible runs. The default will be moved to `0.8.0` as soon as that release is published to the package registry.

## Configuration Discovery

The action is **zero-config by default**. On every run it performs a Root-First search for your Zenzic configuration:

| Priority | Location | When used |
|:---:|---|---|
| 1 | Explicit `config-file` input | Always honoured first if provided |
| 2 | `zenzic.toml` in repository root | Auto-discovered when no explicit override |
| 3 | `.github/zenzic.toml` | Fallback when root file is absent |
| — | *(none found)* | Zenzic uses its built-in defaults |

**Sovereign Intent Contract.** If you supply `config-file: path/to/custom.toml` but the file does not exist, the action **does not fall back** to auto-discovery. You receive a `::warning` annotation (or a fatal `::error` with `strict: true`). Silent fallthrough would be operational deception.

## Sovereign Override — Temporary URL Exclusions

Some documentation links point to pages that are temporarily unavailable in CI (staged deployments, blog posts published simultaneously with the release). The `ZENZIC_EXTRA_ARGS` environment variable lets you pass additional flags directly to the Zenzic CLI without modifying the action inputs:

```yaml
- name: Run Zenzic
  uses: PythonWoods/zenzic-action@v1
  with:
    version: "0.7.1"
    format: sarif
    upload-sarif: "true"
  env:
    ZENZIC_EXTRA_ARGS: >-
      --exclude-url https://example.com/blog/new-post
      --exclude-url https://staging.example.com
```

Each `--exclude-url` value becomes a separate argument. URL patterns that contain `*` or `?` are safe — the wrapper disables glob expansion before building the argument array, so no filesystem expansion occurs.

> **Scope:** `ZENZIC_EXTRA_ARGS` is for transient exclusions only. Permanent rules (e.g. always-exclude a documentation section, configure severity levels) belong in `zenzic.toml` so that local runs and CI share the same policy.

## Inputs

| Input | Default | Description |
|---|---|---|
| `version` | `0.7.1` | Zenzic version to install. Pinned to a specific release for deterministic, reproducible runs. Set `latest` for continuous evaluation of new features. |
| `format` | `sarif` | Output format: `text`, `json`, or `sarif`. |
| `sarif-file` | `zenzic-results.sarif` | SARIF output path (when `format: sarif`). Must be a **relative** path inside the workspace. Absolute paths and `..` traversal sequences are rejected. |
| `upload-sarif` | `true` | Upload SARIF to GitHub Code Scanning. |
| `strict` | `false` | Treat warnings as errors. |
| `fail-on-error` | `true` | Fail the workflow step on findings. |
| `config-file` | *(auto)* | Optional path to a Zenzic configuration file. If omitted, the action auto-discovers: `zenzic.toml` in the repository root first, then `.github/zenzic.toml`. Absolute paths and `..` traversal sequences are rejected. |

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

## Deep Dive — Security Architecture

For a complete description of how the wrapper enforces security, handles exit codes, and performs configuration discovery, see the official documentation:

> **[GitHub Action Internals — zenzic.dev](https://zenzic.dev/docs/explanation/github-action-internals)**
>
> Covers: Path Traversal Guard Protocol · Exit Code Contract · Root-First Zenzic cascade · Sovereign Intent Contract · SARIF integrity guard.

---

## License

Apache-2.0 — see [LICENSE](LICENSE).
