#!/usr/bin/env python3
"""Smoke tests for TurtleTerm bridge feature commands."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
BIN = ROOT / "assets" / "sourceos" / "bin"


def run(args: list[str], env: dict[str, str]) -> dict:
    result = subprocess.run(
        [sys.executable if args[0].endswith(".py") else str(BIN / args[0]), *args[1:]],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        check=False,
    )
    assert result.returncode == 0, result.stderr or result.stdout
    return json.loads(result.stdout)


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        env = dict(os.environ)
        env["SOURCEOS_TERMINAL_EVENTS"] = str(tmp_path / "events.ndjson")
        env["SOURCEOS_TERMINAL_RECEIPTS"] = str(tmp_path / "receipts")
        env["SOURCEOS_WORKSPACE"] = "bridge-feature-test"

        surfaces = run(["turtle-agentctl", "--stdio", "surfaces"], env)
        assert surfaces["kind"] == "surfaces"
        surface_ids = {s["surface_id"] for s in surfaces["data"]["surfaces"]}
        assert "cloudfog/local-devshell" in surface_ids
        assert "agent-machine/local-agentpod" in surface_ids
        assert "neovim/context" in surface_ids

        cloudfog = run(["turtle-cloudfog", "surfaces"], env)
        assert cloudfog["kind"] == "cloudfog_surfaces"

        superconscious = run(["turtle-superconscious", "observe", "hello"], env)
        assert superconscious["kind"] == "superconscious_observation"
        assert superconscious["data"]["decision"]["decision"] == "allow"

        agent_machine = run(["turtle-agent-machine", "surfaces"], env)
        assert agent_machine["kind"] == "agent_machine_surfaces"

        request = run(["turtle-agentctl", "--stdio", "request-surface-execution", "agent-machine/local-agentpod", "echo", "hello"], env)
        assert request["kind"] == "surface_execution_request"
        assert request["data"]["executionAllowed"] is False

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
