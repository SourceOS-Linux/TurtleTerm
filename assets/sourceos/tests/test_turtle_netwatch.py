"""turtle-netwatch — Network/Connections agent. Proven on synthetic fixtures so
it runs offline in CI: graph projection, anomaly detection (beaconing +
egress fan-out), and the fail-closed consent gate on a proposed network action.
"""
from __future__ import annotations

import datetime as dt
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

BIN = Path(__file__).resolve().parents[1] / "bin" / "turtle-netwatch"


def _load():
    from importlib.machinery import SourceFileLoader
    loader = SourceFileLoader("turtle_netwatch", str(BIN))  # extensionless binary
    spec = importlib.util.spec_from_loader("turtle_netwatch", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


nw = _load()


def _obs(raddr, rport, proc, ts, external="true", sev="INFO"):
    return {"schema": "agent.v1.Observation", "source": "netwatch", "type": "net.conn",
            "ts": ts, "severity": sev,
            "attrs": {"proto": "tcp", "raddr": raddr, "rport": rport, "process": proc,
                      "pid": "100", "state": "ESTAB", "external": external}}


def test_schemas_are_valid_avro_json():
    d = BIN.parents[1] / "schemas" / "agent"
    for f in ("observation.avsc", "action.avsc", "knowledge_update.avsc"):
        j = json.loads((d / f).read_text())
        assert j["namespace"] == "agent.v1" and j["type"] == "record"


def test_graph_projects_processes_hosts_ports():
    obs = [_obs("93.184.216.34", "443", "curl", "2026-08-02T00:00:00Z")]
    ku = nw.build_system_graph(obs)
    kinds = {n["kind"] for n in ku["patch"]["nodes"]}
    assert {"Process", "Host", "Port"} <= kinds
    assert ku["graph"] == "SYSTEM"
    assert ku["patch"]["edges"][0]["rel"] == "CONNECTS_TO"


def test_detect_flags_beaconing():
    # 5 contacts to one dst every 60s, near-zero jitter -> beaconing (CRIT)
    base = dt.datetime(2026, 8, 2, tzinfo=dt.timezone.utc)
    obs = [_obs("185.220.101.1", "443", "backdoor",
                (base + dt.timedelta(seconds=60 * i)).isoformat().replace("+00:00", "Z"))
           for i in range(5)]
    findings = nw.detect_anomalies(obs)
    assert any(f["type"] == "net.beaconing" and f["severity"] == "CRIT" for f in findings)


def test_detect_flags_egress_fanout():
    obs = [_obs(f"203.0.113.{i}", "443", "scanner", "2026-08-02T00:00:00Z") for i in range(12)]
    findings = nw.detect_anomalies(obs)
    assert any(f["type"] == "net.egress_fanout" for f in findings)


def test_detect_quiet_on_normal_traffic():
    obs = [_obs("93.184.216.34", "443", "browser", "2026-08-02T00:00:00Z")]
    assert nw.detect_anomalies(obs) == []


def test_propose_fails_closed_without_consent_engine(tmp_path):
    # no policy-fabric reachable -> a network mutation must be REFUSED (exit 3)
    env = dict(os.environ)
    env["SOURCEOS_TERMINAL_RECEIPTS"] = str(tmp_path / "r")
    env["PROPHET_POLICY_FABRIC"] = str(tmp_path / "nonexistent")
    r = subprocess.run([sys.executable, str(BIN), "propose", "--action", "block-domain",
                        "--target", "evil.example", "--json"],
                       env=env, text=True, capture_output=True)
    assert r.returncode == 3, r.stderr
    out = json.loads(r.stdout)
    assert out["decision"] == "deny"
    assert any("fail-closed" in x for x in out["denyReasons"])
    # and it left an auditable refusal receipt
    receipts = (tmp_path / "netwatch" / "actions.jsonl").read_text()
    assert "netwatch.action.refused" in receipts


def test_snapshot_runs_and_is_shaped(tmp_path):
    env = dict(os.environ)
    env["SOURCEOS_TERMINAL_RECEIPTS"] = str(tmp_path / "r")
    r = subprocess.run([sys.executable, str(BIN), "snapshot", "--json"],
                       env=env, text=True, capture_output=True)
    assert r.returncode == 0
    json.loads(r.stdout)  # a list (possibly empty if no ss/lsof) — must be valid JSON


# ------------------------------------------------------------------ Governor loop
def _gov_env(tmp_path):
    env = dict(os.environ)
    env["SOURCEOS_TERMINAL_RECEIPTS"] = str(tmp_path / "r")
    return env


def test_governor_defaults_to_escalate(tmp_path, monkeypatch):
    monkeypatch.setenv("SOURCEOS_TERMINAL_RECEIPTS", str(tmp_path / "r"))
    # no decision recorded -> never a silent admit
    assert nw._governor_decision("net.block", "evil.example") == "escalate"


def test_governor_reads_recorded_decision(tmp_path, monkeypatch):
    monkeypatch.setenv("SOURCEOS_TERMINAL_RECEIPTS", str(tmp_path / "r"))
    d = nw._decisions_path()
    d.parent.mkdir(parents=True, exist_ok=True)
    d.write_text(json.dumps({"actionKey": "net.block|evil.example", "decision": "allow"}) + "\n")
    assert nw._governor_decision("net.block", "evil.example") == "allow"
    # a later deny supersedes
    with d.open("a") as fh:
        fh.write(json.dumps({"actionKey": "net.block|evil.example", "decision": "deny"}) + "\n")
    assert nw._governor_decision("net.block", "evil.example") == "deny"


def test_decide_fails_closed_without_guardrail(tmp_path):
    env = _gov_env(tmp_path)
    env["PROPHET_GUARDRAIL_FABRIC"] = str(tmp_path / "nope")
    r = subprocess.run([sys.executable, str(BIN), "decide", "--action", "block-domain",
                        "--target", "x", "--approve"], env=env, text=True, capture_output=True)
    assert r.returncode == 3  # a network mutation can't be governed -> can't be authorized
    assert "guardrail-fabric" in r.stderr


def test_pending_excludes_decided(tmp_path, monkeypatch):
    monkeypatch.setenv("SOURCEOS_TERMINAL_RECEIPTS", str(tmp_path / "r"))
    sink = nw.state_dir() / "actions.jsonl"
    for tgt in ("a.example", "b.example"):
        rec = {"kind": "netwatch.action.proposed",
               "action": {"capability": "net.block", "args": {"target": tgt}},
               "seal": "s", "ts": "t"}
        with sink.open("a") as fh:
            fh.write(json.dumps(rec) + "\n")
    # decide b.example -> only a.example remains pending
    nw._decisions_path().write_text(json.dumps({"actionKey": "net.block|b.example", "decision": "allow"}) + "\n")

    class A:  # minimal args
        json = True
    import io, contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        nw.cmd_pending(A())
    out = json.loads(buf.getvalue())
    assert [x["target"] for x in out] == ["a.example"]


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-q"]))


def test_graph_ingest_fails_soft_without_hellgraph(tmp_path, monkeypatch):
    # graph --ingest with no hellgraph -> ingested:false, exit 0 (memory, NOT fail-closed)
    monkeypatch.setenv("SOURCEOS_TERMINAL_RECEIPTS", str(tmp_path / "r"))
    monkeypatch.setenv("HELLGRAPH_HOME", str(tmp_path / "no-hellgraph"))
    # seed one observation so the graph has content
    obs = nw.state_dir() / "observations.jsonl"
    obs.write_text(json.dumps(_obs("1.2.3.4", "443", "curl", "2026-08-02T00:00:00Z")) + "\n")
    env = dict(os.environ)
    env["SOURCEOS_TERMINAL_RECEIPTS"] = str(tmp_path / "r")
    env["HELLGRAPH_HOME"] = str(tmp_path / "no-hellgraph")
    r = subprocess.run([sys.executable, str(BIN), "graph", "--ingest"],
                       env=env, text=True, capture_output=True)
    assert r.returncode == 0, r.stderr  # fail-SOFT
    out = json.loads(r.stdout)
    assert out["ingest"]["ingested"] is False
    assert "hellgraph not found" in out["ingest"]["reason"]
