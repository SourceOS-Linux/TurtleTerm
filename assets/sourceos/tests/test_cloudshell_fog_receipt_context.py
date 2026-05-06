#!/usr/bin/env python3
"""Validate TurtleTerm receipt context propagation for CloudShell FOG sessions."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
TURTLE_WRAPPER = REPO_ROOT / "assets" / "sourceos" / "bin" / "turtle-term"


def read_ndjson(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        events = tmp_path / "events.ndjson"
        receipts = tmp_path / "receipts"

        env = dict(os.environ)
        env.update(
            {
                "SOURCEOS_TERMINAL_SESSION_ID": "csf-session-0001",
                "SOURCEOS_WORKSPACE": "workspace:lattice-demo",
                "SOURCEOS_TERMINAL_EVENTS": str(events),
                "SOURCEOS_TERMINAL_RECEIPTS": str(receipts),
                "SOURCEOS_ACTOR_ID": "human:operator@example.com",
                "SOURCEOS_POLICY_BUNDLE_ID": "policy:cloudshell-default",
                "SOURCEOS_EXECUTION_DOMAIN": "cloudshell-fog/k8s",
            }
        )

        result = subprocess.run(
            [sys.executable, str(TURTLE_WRAPPER), "run", "--", sys.executable, "-c", "print('cloudshell-fog-ok')"],
            cwd=str(REPO_ROOT),
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

        assert result.returncode == 0, result.stderr
        assert "cloudshell-fog-ok" in result.stdout
        assert events.exists(), "event stream missing"

        rows = read_ndjson(events)
        completed = [row for row in rows if row.get("event_type") == "command.completed"][-1]
        receipt_path = Path(completed["receipt_path"])
        assert receipt_path.exists(), f"receipt missing: {receipt_path}"

        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        assert receipt["schema"] == "sourceos.terminal.receipt.v0"
        assert receipt["session_id"] == "csf-session-0001"
        assert receipt["workspace_id"] == "workspace:lattice-demo"
        assert receipt["actor_id"] == "human:operator@example.com"
        assert receipt["policy_bundle_id"] == "policy:cloudshell-default"
        assert receipt["execution_domain"] == "cloudshell-fog/k8s"
        assert receipt["stdout_digest"].startswith("sha256:")
        assert receipt["stderr_digest"].startswith("sha256:")

    print("validated CloudShell FOG receipt context propagation")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
