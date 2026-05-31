<!-- SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- markdownlint-disable MD041 -->

## Description

<!-- Describe your changes in detail. Link the issue this PR resolves. -->

Closes #

## Type of change

- [ ] Bug fix
- [ ] New input / output / behaviour
- [ ] SARIF output change
- [ ] Shell / wrapper script change
- [ ] action.yml contract change
- [ ] Documentation update

---

## The Action Contract — mandatory checklist

Every PR that touches `action.yml`, `zenzic-action-wrapper.sh`, or `.github/workflows/` must
satisfy all that apply.

### 1. Exit Code Contract

- [ ] Exit codes 2 (findings) and 3 (path traversal guard) are **never suppressible** via any new
  input or flag — the action must propagate them to the runner unconditionally.
- [ ] `continue-on-error` is **not** set to `true` in any updated workflow example.

### 2. Shell Composability

- [ ] The wrapper script (`zenzic-action-wrapper.sh`) uses POSIX-compatible syntax — no
  bash-isms (`[[ ]]`, `local`, `declare -A`, process substitution) unless the shebang is `#!/usr/bin/env bash`.
- [ ] Any new shell logic has been tested on both bash and sh.

### 3. action.yml Contract

- [ ] The `using: docker` / `using: composite` type is unchanged unless this PR specifically
  changes the action type (requires a major version bump).
- [ ] New inputs have explicit `default:` values where appropriate, and `required: true` only
  when there is no sensible default.
- [ ] The pinned Zenzic version in `action.yml` (if any) is independent from the action's own
  release cycle — updating Zenzic does not force a new action tag.

### 4. SARIF Output Contract

- [ ] The SARIF file produced by this action is valid against the SARIF 2.1.0 schema.
- [ ] No new finding is emitted without a stable `ruleId` that maps to a Zenzic frozen code.

---

## Quality gates

- [ ] `just verify` passes end-to-end.
- [ ] REUSE/SPDX headers are present on every new file.

---

## Notes for reviewers

<!-- Anything unusual about this PR that reviewers should know? -->
