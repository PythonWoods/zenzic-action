# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
"""Nox automation for zenzic-action — the official GitHub Action.

Sessions use external tools (uvx) for REUSE compliance and Zenzic self-checks.
No Python/Node build pipeline — the Action is a shell-based composite action.

Quick reference:
    nox -s reuse       — REUSE/SPDX licence compliance
    nox -s check       — Run Zenzic quality gate on action documentation
    nox -s preflight   — Full CI-equivalent pipeline (reuse + check)
"""

from pathlib import Path

import nox

nox.options.reuse_existing_virtualenvs = True

# Default sessions for fast feedback
nox.options.sessions = ["reuse", "check"]


def _run_zenzic_check(session: nox.Session) -> None:
    """Run Zenzic check using local core when available, else stable published pin.

    TODO(post-pypi-0.8.0): bump fallback from v0.7.1 to v0.8.0.
    """
    core_path = Path(session.env.get("ZENZIC_PROJECT_PATH", "../zenzic"))
    if core_path.is_dir():
        session.log(f"Using local core project: {core_path}")
        session.run(
            "uv",
            "run",
            "--project",
            str(core_path),
            "zenzic",
            "check",
            "all",
            "--strict",
            external=True,
        )
        return
    session.log("Local core project not found; using published zenzic@v0.7.1")
    session.run("uvx", "zenzic@v0.7.1", "check", "all", "--strict", external=True)


@nox.session(venv_backend="none")
def reuse(session: nox.Session) -> None:
    """Verify REUSE/SPDX licence compliance."""
    session.run("uvx", "reuse", "lint", external=True)


@nox.session(venv_backend="none")
def check(session: nox.Session) -> None:
    """Run the Zenzic quality gate on action documentation."""
    _run_zenzic_check(session)


@nox.session(venv_backend="none")
def tests(session: nox.Session) -> None:
    """Run action smoke tests and shell validation."""
    session.run("bash", "-n", "zenzic-action-wrapper.sh", external=True)
    _run_zenzic_check(session)


@nox.session(venv_backend="none")
def preflight(session: nox.Session) -> None:
    """Full CI-equivalent pipeline: reuse → check."""
    session.run("uvx", "reuse", "lint", external=True)
    _run_zenzic_check(session)
