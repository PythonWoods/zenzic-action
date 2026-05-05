<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/zenzic-wordmark-action-dark.svg">
    <img alt="Zenzic / action" src="assets/zenzic-wordmark-action.svg" width="350">
  </picture>
</p>

<p align="center">Il punto di enforcement deterministico per l'integrità della documentazione in CI. I codici di uscita sono contrattuali — exit 2 e 3 sopravvivono a <code>fail-on-error: false</code>.</p>

<p align="center">
  <a href="https://github.com/PythonWoods/zenzic-action/releases"><img alt="action version" src="https://img.shields.io/github/v/release/PythonWoods/zenzic-action?label=action&color=4f46e5"></a>
  <a href="https://pypi.org/project/zenzic"><img alt="zenzic on PyPI" src="https://img.shields.io/pypi/v/zenzic?label=zenzic&color=0284c7"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-Apache--2.0-blue"></a>
  <a href="https://zenzic.dev/it/developers/explanation/adr-vault"><img alt="4-Gates: Sentinel Seal" src="https://img.shields.io/badge/4--Gates-Sentinel%20Seal-10b981?style=flat-square"></a>
  <a href="https://reuse.software/"><img alt="REUSE 3.x compliant" src="https://img.shields.io/badge/REUSE-3.x%20compliant-0d9488?style=flat-square"></a>
</p>

---

Esegui i check Zenzic in CI e fai emergere i risultati direttamente in GitHub Code Scanning, nelle annotation delle Pull Request e nel tab Security — senza leggere log.

**Contratto exit code.** Il wrapper propagates i codici di uscita di Zenzic senza rimappatura. Exit 1 (qualità) obbedisce a `fail-on-error`. Exit 2 (credenziale) ed exit 3 (path traversal) terminano il job indipendentemente da `fail-on-error: false` o `--exit-zero` — i finding di sicurezza non vengono mai soppressi al boundary di enforcement.

<p align="center">
  <img alt="GitHub Code Scanning showing Zenzic findings" src="assets/sarif-showcase.svg" width="780">
</p>

## Funzionalità Principali

| Funzionalità | Descrizione |
|---|---|
| Install zero-setup | `uvx zenzic` — nessuna toolchain Python richiesta sul runner |
| Output SARIF | I finding alimentano direttamente GitHub Code Scanning |
| Contratto Exit Code | Gli incidenti di sicurezza (exit 2/3) non vengono mai soppressi da `fail-on-error` |
| Check integrità SARIF | Valida il JSON prima dell'upload; emette `::warning` se troncato da SIGKILL |
| Annotation PR | Finding inline sul diff, color-coded per severity |
| Version pinning | Pin a una release esatta per gate CI deterministici e riproducibili |

## Utilizzo

```yaml
- name: Run Zenzic Documentation Quality Gate
  uses: PythonWoods/zenzic-action@v1
  with:
    format: sarif
    upload-sarif: "true"
```

Aggiungi `permissions: security-events: write` al job per far riuscire l'upload SARIF.

Esempio completo:

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
          version: "0.7.0"       # pin a una release stabile
          format: sarif           # emetti SARIF per Code Scanning
          upload-sarif: "true"    # invia i risultati al tab Security
          strict: "false"
          fail-on-error: "true"
```

> **Directory docs:** Zenzic legge la sua configurazione da `zenzic.toml` nella root del repository.
> Esegui `zenzic init` una volta per fare scaffolding di un config se le tue docs sono fuori dalla cartella `docs/` di default.

> **Stabilità:** `version: "0.7.0"` è il default. Per le ultime feature appena rilasciate, puoi impostare `version: latest`, ma le pipeline di produzione dovrebbero sempre fare pin a una release specifica per esecuzioni deterministiche e riproducibili.

## Inputs

| Input | Default | Descrizione |
|---|---|---|
| `version` | `0.7.0` | Versione di Zenzic da installare. Pin a una release specifica per esecuzioni deterministiche. Imposta `latest` per valutazione continua di nuove feature. |
| `format` | `sarif` | Formato di output: `text`, `json`, o `sarif`. |
| `sarif-file` | `zenzic-results.sarif` | Path di output SARIF (quando `format: sarif`). Deve essere un path **relativo** dentro il workspace. Path assoluti e sequenze di traversal `..` sono rifiutati. |
| `upload-sarif` | `true` | Carica SARIF su GitHub Code Scanning. |
| `strict` | `false` | Tratta i warning come errori. |
| `fail-on-error` | `true` | Fa fallire lo step del workflow sui finding. |

## Outputs

| Output | Descrizione |
|---|---|
| `sarif-file` | Path al file SARIF generato. |
| `findings-count` | Numero totale di finding. |

## SARIF & GitHub Code Scanning

Quando `format: sarif` e `upload-sarif: true`, i finding di Zenzic appaiono:

- Nel tab **Security → Code Scanning** del repository.
- Come **annotation inline** sui diff delle Pull Request.
- Color-coded per severity: errori in rosso, warning in giallo, finding di sicurezza con punteggio in stile CVSS (`9.5` per leak di credenziali, `9.0` per incidenti di path-traversal).

Nessuna configurazione aggiuntiva necessaria — l'action gestisce l'upload tramite `github/codeql-action/upload-sarif`.

## Come funziona

1. Installa `uv` con cache abilitata.
2. Esegue `uvx "zenzic==<version>"` (o `uvx zenzic` per latest) — un'unica invocazione isolata, nessuno step di pre-install.
3. Scrive il report SARIF su `sarif-file` (solo stdout; stderr fluisce sul log dello step).
4. Valida l'integrità JSON SARIF — emette un'annotation `::warning` se il file è troncato (es. per SIGKILL).
5. Carica tramite `github/codeql-action/upload-sarif`.

## Ambienti Supportati

| Componente | Minimo | Raccomandato | Note |
|:--|:--|:--|:--|
| **Runner GitHub-hosted** | `ubuntu-22.04` | `ubuntu-latest` | Anche i runner macOS e Windows sono supportati |
| **Runner self-hosted** | Qualsiasi OS con `bash` ≥ 5 e `python3` ≥ 3.11 | — | `uv` viene installato dall'action; nessun pre-install richiesto |
| **Node.js** | 24 | 24 | Richiesto da `github/codeql-action/upload-sarif@v4` |
| **`astral-sh/setup-uv`** | v8 | v8 | Le versioni precedenti non hanno il supporto cache cross-platform completo |
| **`github/codeql-action`** | v4 | v4 | v3 deprecato; v2 end-of-life a marzo 2024 |
| **`actions/checkout`** | v6 | v6 | Deve essere eseguito prima di questa action |

> **Runner self-hosted:** assicurati che `python3` (3.11+) e `bash` (5+) siano disponibili nel `PATH`.
> `uv` viene installato dall'action tramite `astral-sh/setup-uv` — nessuna toolchain Python pre-installata necessaria.

## Ecosistema

| Componente | Repository / URL | Descrizione |
|---|---|---|
| **Zenzic CLI** | [PythonWoods/zenzic](https://github.com/PythonWoods/zenzic) | Linter core — installa con `pip install zenzic` o esegui via `uvx zenzic` |
| **Documentazione** | [zenzic.dev](https://zenzic.dev) | Reference di configurazione, catalogo regole e how-to |
| **Brand System** | [zenzic.dev/assets/brand/zenzic-brand-system.html](https://zenzic.dev/assets/brand/zenzic-brand-system.html) | Identità visiva, badge e asset SVG |
| **zenzic-action** | [PythonWoods/zenzic-action](https://github.com/PythonWoods/zenzic-action) | Questo repository |

---

## 📖 Mappa della Documentazione — La Promessa di Quarzo

La documentazione di Zenzic vive in **due istanze Docusaurus separate** sotto
[zenzic.dev](https://zenzic.dev) — l'area utente e l'area sviluppatori non
condividono mai una sidebar o un indice di ricerca.

```text
zenzic.dev/
├── docs/           → Area Utente   — installazione, configurazione, CI/CD, codici
├── developers/     → Area Dev      — plugin, adapter, ADR, ledger del debito tecnico
├── blog/           → Note di rilascio e post-mortem ingegneristici
└── community/      → Brand kit, FAQ, governance
```

La separazione è imposta da [ADR 011: Cross-Instance Allowlist](https://zenzic.dev/it/developers/explanation/adr-cross-instance-allowlist) — ogni link che attraversa il confine è un contratto documentato, mai una soppressione silenziosa.

| Sei un... | Inizia da qui |
| :--- | :--- |
| 👤 Utente dell'action (integrator CI) | [Guida CI/CD](https://zenzic.dev/it/docs/how-to/configure-ci-cd/) |
| 🔧 Contributor dell'action | [Portale Sviluppatori](https://zenzic.dev/it/developers/) · [ADR Vault](https://zenzic.dev/it/developers/explanation/adr-vault) |
| 🛡️ Security reviewer | [Engineering Ledger](https://zenzic.dev/it/developers/explanation/engineering-ledger) · [SECURITY.md](SECURITY.md) |

---

## Licenza

Apache-2.0 — vedi [LICENSE](LICENSE).
