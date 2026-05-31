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

<p align="center">Il punto di enforcement deterministico per l'integrità della documentazione in CI. I codici di uscita sono contrattuali — exit 2 e 3 sopravvivono a <code>fail-on-error: false</code>.</p>

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

Esegui i check Zenzic in CI e fai emergere i risultati direttamente in GitHub Code Scanning, nelle annotation delle Pull Request e nel tab Security — senza leggere log.

**Contratto exit code.** Il wrapper propaga i codici di uscita di Zenzic senza rimappatura. Exit 1 (qualità) obbedisce a `fail-on-error`. Exit 2 (credenziale) ed exit 3 (path traversal) terminano il job indipendentemente da `fail-on-error: false` o `--exit-zero` — i finding di sicurezza non vengono mai soppressi al boundary di enforcement.

## Funzionalità Principali

| Funzionalità | Descrizione |
|---|---|
| Install zero-setup | `uvx zenzic` — nessuna toolchain Python richiesta sul runner |
| Output SARIF | I finding alimentano direttamente GitHub Code Scanning |
| Contratto Exit Code | Gli incidenti di sicurezza (exit 2/3) non vengono mai soppressi da `fail-on-error` |
| Modalità Sovereign Audit | `audit: "true"` bypassa tutte le soppressioni — rivela il vero stato della documentazione |
| Check integrità SARIF | Valida il JSON prima dell'upload; emette `::warning` se troncato da SIGKILL |
| Annotation PR | Finding inline sul diff, codificati a colori per severità |
| Version pinning | Pin a una release esatta per gate CI deterministici e riproducibili |
| **Prosa pulita** | `[governance.directory_policies]` in `.zenzic.toml` concede esenzioni zero-debt a pattern di percorso |

## Quick Start

La configurazione minimale — zero setup Python, SARIF su Code Scanning in un solo step:

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

Metti un file `.zenzic.toml` nella root del repository e l'action lo trova automaticamente — nessun input `config-file` richiesto. Esegui `zenzic init` una volta per fare scaffolding della configurazione se le tue docs sono fuori dalla cartella `docs/` di default.

Per la configurazione avanzata (Configuration Discovery, Override Sovrano, scoring del Quality Gate, audit notturno), consulta la [documentazione di Zenzic Action](https://zenzic.dev/it/docs/reference/zenzic-action).

---

## Inputs

| Input | Default | Descrizione |
|---|---|---|
| `version` | `0.8.1` | Versione di Zenzic da installare. Pin a una release specifica per esecuzioni deterministiche. Imposta `latest` per valutazione continua. |
| `format` | `sarif` | Formato di output: `text`, `json`, o `sarif`. |
| `sarif-file` | `zenzic-results.sarif` | Path di output SARIF (quando `format: sarif`). Deve essere un path **relativo** dentro il workspace. |
| `upload-sarif` | `true` | Carica SARIF su GitHub Code Scanning. |
| `strict` | `false` | Tratta i warning come errori. |
| `fail-on-error` | `true` | Fa fallire lo step del workflow sui finding. |
| `config-file` | *(auto)* | Path opzionale a un file di configurazione. Auto-scopre `.zenzic.toml` → `.github/.zenzic.toml` se omesso. |
| `audit` | `false` | Modalità sovereign audit: bypassa tutti i `zenzic:ignore` e `per_file_ignores`. Rivela il vero stato non filtrato della documentazione. Raccomandato per build notturne e workflow di security review. |
| `diff-base` | *(snapshot)* | Path a un file di baseline JSON per `zenzic diff`. Usa un artifact dal branch `main` per bloccare PR che aumentano il debito tecnico. Se omesso, usa `.zenzic-score.json`. |
| `guard-scan` | `false` | Esegue `zenzic guard scan` come step Defense-in-Depth **prima** del gate principale. Rileva credenziali hardcodate e pattern vietati che hanno bypassato i pre-commit hook. Il fallimento è sempre fatale — non è governato da `fail-on-error`. |

## Outputs

| Output | Descrizione |
|---|---|
| `sarif-file` | Path al file SARIF generato. |
| `findings-count` | Numero totale di finding. |
| `score` | Documentation Quality Score (0–100). Disponibile con `format: json` o quando `diff-base` è impostato. |
| `suppression-debt-pts` | Punti di Debito Tecnico detratti dal punteggio per soppressioni attive. `0` quando non ci sono soppressioni. |
| `cap-exceeded` | `"true"` quando il CAP di soppressione è stato superato e ha bloccato la build; `"false"` altrimenti. |

## Workflow Avanzati

### Blocco della Regressione del Debito

Blocca le pull request che aumentano il debito documentale. Salva una baseline da `main` come artifact del workflow; il job di quality-gate la scarica e fallisce se `zenzic diff` rileva un calo del punteggio.

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

### Audit Sovrano Notturno

Esegui ogni notte un audit completo non filtrato per rivelare il vero stato della documentazione — bypassando tutti i commenti `zenzic:ignore` e i `per_file_ignores`. I finding soppressi nel CI quotidiano sono visibili qui.

```yaml
on:
  schedule:
    - cron: "0 3 * * *"   # 03:00 UTC ogni giorno

jobs:
  sovereign-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Audit sovrano (nessuna soppressione)
        uses: PythonWoods/zenzic-action@v1
        with:
          audit: "true"
          format: sarif
          upload-sarif: "true"
```

### Utilizzo degli Output dell'Action

Cattura `score`, `suppression-debt-pts` e `cap-exceeded` per logica condizionale o reportistica downstream.

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

  - name: Fallisci se il CAP di soppressione è superato
    if: steps.zenzic.outputs.cap-exceeded == 'true'
    run: |
      echo "::error::Suppression CAP superato — build bloccata."
      exit 1
```

---

## Codici di Uscita

| Codice | Significato | Sopprimibile? |
|:---:|---|:---:|
| `0` | Tutti i check superati | — |
| `1` | Finding di documentazione (link rotti, orfani, CAP soppressioni) | Sì (`fail-on-error: "false"`) |
| **`2`** | **Credenziale rilevata (Z201)** | **Mai** |
| **`3`** | **Path traversal rilevato (Z202/Z203)** | **Mai** |

---

Per la governance avanzata (Scoring & Debt, Sovereign Audit, Quality Gate PR blocking), consulta la
[documentazione di Zenzic Action](https://zenzic.dev/it/docs/reference/zenzic-action).

Per gli internals dell'architettura di sicurezza (contratto exit code, Root-First discovery, guardia integrità SARIF),
consulta l'[Engineering Ledger](https://zenzic.dev/it/developers/explanation/engineering-ledger).

## Licenza

Apache-2.0 — vedi [LICENSE](LICENSE).
