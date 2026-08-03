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


# --------------------------------------------------------------------- consent-plane
def _agentd_module():
    """Import turtle-agentd (extensionless) to unit-test the consent-plane envelope."""
    from importlib.machinery import SourceFileLoader
    import importlib.util
    loader = SourceFileLoader("turtle_agentd_mod", str(AGENTD))
    spec = importlib.util.spec_from_loader("turtle_agentd_mod", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


_ad = _agentd_module()


def test_agent_actor_detection():
    assert _ad._is_agent_actor("urn:srcos:agent:turtle-copilot")
    assert _ad._is_agent_actor("agent:autonomous")
    assert _ad._is_agent_actor("mystery:actor")  # unknown -> governed (fail-closed)
    assert not _ad._is_agent_actor("human:local-user")  # only explicit human has authority
    assert not _ad._is_agent_actor("")  # empty == daemon's default human path


def test_agent_egress_denied_on_terminal_surface():
    for cmd in ("git push origin main", "kubectl apply -f x.yaml", "curl https://evil.example",
                "gh pr merge 12", "docker push repo/img", "scp f user@host:/tmp"):
        d, reason = _ad.consent_plane_check(cmd, "agent:autonomous")
        assert d == "deny", cmd
        assert "consent-plane" in reason


def test_agent_read_edit_test_allowed_on_terminal():
    for cmd in ("ls -la", "cat README.md", "grep -r foo .", "git status", "git diff",
                "pytest -q", "cargo test"):
        d, _ = _ad.consent_plane_check(cmd, "agent:autonomous")
        assert d == "allow", cmd


def test_human_keeps_full_authority():
    # the envelope governs agents only — a human may push/deploy
    d, _ = _ad.consent_plane_check("git push origin main", "human:local-user")
    assert d == "allow"


def test_policy_evaluate_denies_agent_egress():
    # deny short-circuits before Policy Fabric, offline
    r = _ad.policy_evaluate("terminal.execute_command", "git push origin main",
                            execution_domain="host", actor_id="agent:autonomous")
    assert r["decision"]["outcome"] == "deny"
    assert r["source"] == "consent-plane"
