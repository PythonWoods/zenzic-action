<!--
SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
SPDX-License-Identifier: Apache-2.0
-->

# Contribuire a zenzic-action

Grazie per il tuo contributo alla GitHub Action ufficiale di Zenzic.

## Dipendenza Core

La distribuzione runtime per gli utenti a valle resta agganciata alle release
pubblicate di Zenzic. I quality gate del repository (self-check, just, nox),
invece, usano il modello sovrano locale-core condiviso.

La risoluzione della branch parity in CI segue questa precedenza:

1. Override esplicito tramite la repository variable `ZENZIC_CORE_REF`.
2. Parità di nome del branch (`github.base_ref` o `github.ref_name`).
3. Fallback su `main` se il branch target non esiste in core.

Usa `ZENZIC_CORE_REF` quando la nomenclatura dei branch di zenzic-action
diverge da quella dei repository core (ad esempio, branch di release
dell'action vs. branch di release del core).

La governance dell'override è obbligatoria (fail-closed): quando
`ZENZIC_CORE_REF` è impostata, sono richieste le seguenti repository variables:

1. `ZENZIC_CORE_REF_TICKET` (ticket di change/audit)
2. `ZENZIC_CORE_REF_REASON` (giustificazione esplicita)
3. `ZENZIC_CORE_REF_APPROVER` (owner che ha approvato)
4. `ZENZIC_CORE_REF_EXPIRES_ON` (data UTC in formato `YYYY-MM-DD`)

Se i metadati mancano, sono malformati, scaduti o il branch non esiste in
core, la CI si arresta con un errore esplicito.

## Policy di Governance Enterprise e Contributo

Per garantire la sicurezza, l'integrità architetturale e la conformità legale di Zenzic, tutti i contributi devono aderire alle seguenti linee guida di Governance Enterprise:

1. **Issue-First Policy (Prima le Issue)**: Nessuna Pull Request sarà presa in carico, revisionata o discussa se non preceduta da una Issue corrispondente discussa e approvata dai maintainer. Collega sempre l'Issue approvata nella descrizione della tua PR.
2. **Firma Crittografica Obbligatoria**: Tutti i commit devono essere firmati crittograficamente tramite chiavi GPG, SSH o S/MIME (mostrati come "Verified" su GitHub). I commit non firmati verranno respinti automaticamente dal gate di merge.
3. **Clausola "No AI Slop"**: Applichiamo una policy severa contro il codice generato da intelligenza artificiale non verificato. I contributor devono comprendere appieno, saper spiegare e giustificare dal punto di vista architetturale ogni singola riga di codice proposta nella PR. La proposta di codice non compreso porterà al rifiuto immediato del contributo.
4. **Developer Certificate of Origin (DCO)**: Tutti i commit devono includere la riga `Signed-off-by:` (usando `git commit -s`) per certificare la conformità con la DCO.
5. **Conventional Commits**: I messaggi di commit devono seguire rigorosamente la specifica Conventional Commits (es. `feat: add block anchor support (#123)`).

## Setup Iniziale

Installa gli hook pre-commit (una sola volta dopo il clone):

```bash
uvx pre-commit install               # commit-stage: hygiene + zenzic self-check
uvx pre-commit install -t pre-push   # pre-push: 🛡️ Final Guard runs `just verify`
```

## Verifica Locale

Usa `just` per eseguire i self-test prima di aprire una PR:

```bash
just lint      # fast pass: pre-commit hooks only
just verify    # full gate: pre-commit + Zenzic check + integration tests
```

Entrambi devono passare con zero errori prima di aprire o aggiornare una PR.

## Maintainer Only: Workflow Hardening

### Immutable Pre-Commit Hooks (ADR-089)

Tutte le chiavi `rev:` in `.pre-commit-config.yaml` devono puntare a un
**pin immutabile a commit hash**, mai a un tag semantico (`v1.2.3`). I tag git
sono mutabili: un maintainer upstream (o un attaccante) può spostare un tag
silenziosamente, avvelenando il Gate 2 locale senza alcun diff in questo
repository.

Questa è una **policy CI interna del progetto zenzic-action**, non una regola
pubblica del linter Zenzic. Enforcement: `just check-pinning` (dipendenza di
`just verify`); le violazioni sollevano `[ADR-089] FATAL` in pre-push.

La finestra di esposizione locale è più piccola di quella GHA perché
`pre-commit` congela i repo degli hook in `~/.cache/pre-commit/` finché
l'utente non lancia `autoupdate` o `clean`; GitHub Actions invece ri-risolve
il ref a ogni esecuzione. Il pinning è comunque obbligatorio in locale per la
sicurezza dei nuovi clone e per la parità con l'enforcement ADR-089 remoto.

**Aggiornare gli hook pinned.** Non eseguire mai il `pre-commit autoupdate`
nudo — riscrive le SHA tornando a tag mutabili. Usa sempre:

```bash
uvx pre-commit autoupdate --freeze
```

Questo preserva il commento di annotazione `# vX.Y.Z`. Committa il diff e
ri-verifica con `just check-pinning`.
