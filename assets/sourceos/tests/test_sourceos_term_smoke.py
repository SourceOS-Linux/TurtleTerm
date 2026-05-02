#!/usr/bin/env python3
"""Smoke tests for TurtleTerm / SourceOS terminal command wrappers v0."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SOURCEOS_WRAPPER = REPO_ROOT / "assets" / "sourceos" / "bin" / "sourceos-term"
TURTLE_WRAPPER = REPO_ROOT / "assets" / "sourceos" / "bin" / "turtle-term"


def read_ndjson(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def run_wrapper(wrapper: Path, session_id: str, workspace: str, expected_text: str) -> tuple[list[dict], dict]:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        events = tmp_path / "events.ndjson"
        receipts = tmp_path / "receipts"

        env = dict(os.environ)
        env.update(
            {
                "SOURCEOS_TERMINAL_SESSION_ID": session_id,
                "SOURCEOS_WORKSPACE": workspace,
                "SOURCEOS_TERMINAL_EVENTS": str(events),
                "SOURCEOS_TERMINAL_RECEIPTS": str(receipts),
                "SOURCEOS_ACTOR_ID": "test:smoke",
                "SOURCEOS_POLICY_BUNDLE_ID": "policy:test",
                "SOURCEOS_EXECUTION_DOMAIN": "host",
            }
        )
        env.pop("SOURCEOS_TERMINAL_FRONTEND", None)

        result = subprocess.run(
            [sys.executable, str(wrapper), "run", "--", sys.executable, "-c", f"print('{expected_text}')"],
            cwd=str(REPO_ROOT),
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

        assert result.returncode == 0, result.stderr
        assert expected_text in result.stdout
        assert events.exists(), "event stream missing"

        event_rows = read_ndjson(events)
        schemas = [row.get("schema") for row in event_rows]
        event_types = [row.get("event_type") for row in event_rows if row.get("schema") == "sourceos.terminal.event.v0"]

        assert "sourceos.terminal.session.v0" in schemas
        assert "command.started" in event_types
        assert "command.completed" in event_types

        completed = [row for row in event_rows if row.get("event_type") == "command.completed"][-1]
        receipt_path = Path(completed["receipt_path"])
        assert receipt_path.exists(), f"receipt missing: {receipt_path}"

        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        assert receipt["schema"] == "sourceos.terminal.receipt.v0"
        assert receipt["session_id"] == session_id
        assert receipt["workspace_id"] == workspace
        assert receipt["exit_status"] == 0
        assert receipt["command_argv"][-2:] == ["-c", f"print('{expected_text}')"]
        assert receipt["stdout_digest"].startswith("sha256:")
        assert receipt["stderr_digest"].startswith("sha256:")

        session = [row for row in event_rows if row.get("schema") == "sourceos.terminal.session.v0"][-1]
        return event_rows, session


def main() -> int:
    _, sourceos_session = run_wrapper(SOURCEOS_WRAPPER, "sourceos-term-test", "sourceos-test", "sourceos-smoke")
    assert sourceos_session["frontend"] == "sourceos-term"

    _, turtle_session = run_wrapper(TURTLE_WRAPPER, "turtle-term-test", "turtle-test", "turtle-smoke")
    assert turtle_session["frontend"] == "turtle-term"

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
