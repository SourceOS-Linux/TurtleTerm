#!/usr/bin/env python3
"""Smoke tests for turtle-agentd and turtle-agentctl v0."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
AGENTD = ROOT / "assets" / "sourceos" / "bin" / "turtle-agentd"
AGENTCTL = ROOT / "assets" / "sourceos" / "bin" / "turtle-agentctl"


def run_agentd(request: dict, env: dict[str, str]) -> dict:
    result = subprocess.run(
        [sys.executable, str(AGENTD), "--stdio"],
        input=json.dumps(request),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        check=False,
    )
    assert result.returncode == 0, result.stderr or result.stdout
    return json.loads(result.stdout)


def run_agentctl(args: list[str], env: dict[str, str]) -> dict:
    result = subprocess.run(
        [sys.executable, str(AGENTCTL), "--stdio", *args],
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
        events = tmp_path / "events.ndjson"
        receipts = tmp_path / "receipts"
        env = dict(os.environ)
        env["SOURCEOS_TERMINAL_EVENTS"] = str(events)
        env["SOURCEOS_TERMINAL_RECEIPTS"] = str(receipts)

        ping = run_agentd({"action": "ping"}, env)
        assert ping["status"] == "ok"
        assert ping["kind"] == "pong"
        assert ping["data"]["service"] == "turtle-agentd"

        proposal = run_agentctl(["propose", "echo", "hello"], env)
        assert proposal["kind"] == "command_proposal"
        assert proposal["data"]["requiresDecision"] is True
        assert proposal["data"]["decision"]["decision"] == "ask"

        execution = run_agentctl(["request-execution", "echo", "hello"], env)
        assert execution["kind"] == "execution_request"
        assert execution["data"]["executionAllowed"] is False
        assert execution["data"]["decision"]["decision"] == "ask"

        sessions = run_agentctl(["sessions"], env)
        assert sessions["kind"] == "sessions"
        assert sessions["data"]["sessions"] == []

        summary = run_agentctl(["summarize"], env)
        assert summary["kind"] == "summary"
        assert summary["data"]["event_count"] == 0

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
