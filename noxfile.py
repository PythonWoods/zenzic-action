# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
"""Nox automation for zenzic-action — the official GitHub Action.

Sessions use external tools (uvx) for REUSE compliance and Zenzic self-checks.
No Python/Node build pipeline — the Action is a shell-based composite action.

Quick reference:
    nox -s reuse       — REUSE/SPDX licence compliance
    nox -s check       — Run Zenzic Sentinel on action documentation
    nox -s preflight   — Full CI-equivalent pipeline (reuse + check)
"""

import nox

nox.options.reuse_existing_virtualenvs = True

# Default sessions for fast feedback
nox.options.sessions = ["reuse", "check"]


@nox.session(venv_backend="none")
def reuse(session: nox.Session) -> None:
    """Verify REUSE/SPDX licence compliance."""
    session.run("uvx", "reuse", "lint", external=True)


@nox.session(venv_backend="none")
def check(session: nox.Session) -> None:
    """Run the Zenzic Sentinel quality gate on action documentation."""
    session.run("uvx", "zenzic", "check", "all", external=True)


@nox.session(venv_backend="none")
def preflight(session: nox.Session) -> None:
    """Full CI-equivalent pipeline: reuse → check."""
    session.run("uvx", "reuse", "lint", external=True)
    session.run("uvx", "zenzic", "check", "all", external=True)
