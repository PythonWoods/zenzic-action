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
  <a href="https://zenzic.dev/it/developers/explanation/adr-vault"><img alt="4-Gates: Zenzic Audit Badge" src="https://img.shields.io/badge/4--Gates-Zenzic%20Audit%20Badge-10b981?style=flat-square"></a>
  <a href="https://reuse.software/"><img alt="REUSE 3.x compliant" src="https://img.shields.io/badge/REUSE-3.x%20compliant-0d9488?style=flat-square"></a>
</p>

---

Esegui i check Zenzic in CI e fai emergere i risultati direttamente in GitHub Code Scanning, nelle annotation delle Pull Request e nel tab Security — senza leggere log.

**Contratto exit code.** Il wrapper propagates i codici di uscita di Zenzic senza rimappatura. Exit 1 (qualità) obbedisce a `fail-on-error`. Exit 2 (credenziale) ed exit 3 (path traversal) terminano il job indipendentemente da `fail-on-error: false` o `--exit-zero` — i finding di sicurezza non vengono mai soppressi al boundary di enforcement.

## Funzionalità Principali

| Funzionalità | Descrizione |
|---|---|
| Install zero-setup | `uvx zenzic` — nessuna toolchain Python richiesta sul runner |
| Output SARIF | I finding alimentano direttamente GitHub Code Scanning |
| Contratto Exit Code | Gli incidenti di sicurezza (exit 2/3) non vengono mai soppressi da `fail-on-error` |
| Modalità Sovereign Audit | `audit: "true"` bypassa tutte le soppressioni — rivela il vero stato della documentazione |
| Check integrità SARIF | Valida il JSON prima dell'upload; emette `::warning` se troncato da SIGKILL |
| Annotation PR | Finding inline sul diff, color-coded per severity |
| Version pinning | Pin a una release esatta per gate CI deterministici e riproducibili |
| **Prosa pulita** | `[governance.directory_policies]` in `zenzic.toml` concede esenzioni zero-debt a pattern di percorso |

## Quick Start

La configurazione minimale — zero setup Python, SARIF su Code Scanning in un solo step:

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

Metti un file `zenzic.toml` nella root del repository e l'action lo trova automaticamente — nessun input `config-file` richiesto. Esegui `zenzic init` una volta per fare scaffolding della configurazione se le tue docs sono fuori dalla cartella `docs/` di default.

Per la configurazione avanzata (Configuration Discovery, Override Sovrano, scoring del Quality Gate, audit notturno), consulta la [documentazione di Zenzic Action](https://zenzic.dev/it/docs/reference/zenzic-action).

---

## Inputs

| Input | Default | Descrizione |
|---|---|---|
| `version` | `0.7.1` | Versione di Zenzic da installare. Pin a una release specifica per esecuzioni deterministiche. Imposta `latest` per valutazione continua. |
| `format` | `sarif` | Formato di output: `text`, `json`, o `sarif`. |
| `sarif-file` | `zenzic-results.sarif` | Path di output SARIF (quando `format: sarif`). Deve essere un path **relativo** dentro il workspace. |
| `upload-sarif` | `true` | Carica SARIF su GitHub Code Scanning. |
| `strict` | `false` | Tratta i warning come errori. |
| `fail-on-error` | `true` | Fa fallire lo step del workflow sui finding. |
| `config-file` | *(auto)* | Path opzionale a un file di configurazione. Auto-scopre `zenzic.toml` → `.github/zenzic.toml` se omesso. |
| `audit` | `false` | Modalità sovereign audit: bypassa tutti i `zenzic:ignore` e `per_file_ignores`. Raccomandato per build notturne e workflow di security review. |
| `diff-base` | *(snapshot)* | Path a un file di baseline JSON per `zenzic diff`. Usa un artifact dal branch `main` per bloccare PR che aumentano il debito tecnico. |

## Outputs

| Output | Descrizione |
|---|---|
| `sarif-file` | Path al file SARIF generato. |
| `findings-count` | Numero totale di finding. |
| `score` | Documentation Quality Score (0–100). Disponibile con `format: json` o quando `diff-base` è impostato. |
| `suppression-debt-pts` | Punti di Debito Tecnico detratti dal punteggio per soppressioni attive. `0` quando non ci sono soppressioni. |

## Codici di Uscita

| Codice | Significato | Sopprimibile? |
|:---:|---|:---:|
| `0` | Tutti i check superati | — |
| `1` | Finding di documentazione | Sì (`fail-on-error: "false"`) |
| **`2`** | **Credenziale rilevata (Z201)** | **Mai** |
| **`3`** | **Path traversal rilevato (Z202/Z203)** | **Mai** |

---

Per la governance avanzata (Scoring & Debt, Sovereign Audit, Quality Gate PR blocking), consulta la
[documentazione di Zenzic Action](https://zenzic.dev/it/docs/reference/zenzic-action).

Per gli internals dell'architettura di sicurezza (contratto exit code, Root-First discovery, guardia integrità SARIF),
consulta l'[Engineering Ledger](https://zenzic.dev/it/developers/explanation/engineering-ledger).

## Licenza

Apache-2.0 — vedi [LICENSE](LICENSE).
