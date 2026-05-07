#!/usr/bin/env python3
"""Verify TurtleTerm Agent Harness terminal receipt fixture."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / "schemas" / "agent-harness-terminal-receipts.schema.json"
EXAMPLE = ROOT / "examples" / "agent-harness-terminal-receipts.example.json"


class ValidationError(Exception):
    pass


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate(data: dict[str, Any]) -> None:
    require(SCHEMA.exists(), f"missing schema: {SCHEMA}")
    require(data.get("schemaVersion") == "v0.1", "schemaVersion must be v0.1")
    require(data.get("kind") == "AgentHarnessTerminalReceipts", "kind mismatch")

    session = data.get("terminalSessionReceipt")
    require(isinstance(session, dict), "terminalSessionReceipt must be object")
    for field in ["sessionId", "actorRef", "workspaceRef", "shellProfile", "gatewayProfile", "policyAdmissionRef", "agentplaneRunRef", "environmentProfileHash"]:
        require(field in session, f"terminalSessionReceipt missing {field}")
    require(session["environmentProfileHash"].startswith("sha256:"), "environmentProfileHash must be a sha256 ref")

    command = data.get("commandReceipt")
    require(isinstance(command, dict), "commandReceipt must be object")
    for field in ["commandId", "terminalSessionRef", "commandHash", "workingDirectory", "environmentProfileHash", "exitCode", "policyDecisionRef", "sideEffectClass", "replayEligible"]:
        require(field in command, f"commandReceipt missing {field}")
    require(command["commandHash"].startswith("sha256:"), "commandHash must be a sha256 ref")
    require(command["policyDecisionRef"], "commandReceipt requires policyDecisionRef")
    if command["exitCode"] != 0:
        require(command["replayEligible"] is False, "failed command should not be replayEligible in baseline fixture")

    mutation = data.get("mutationReceipt")
    require(isinstance(mutation, dict), "mutationReceipt must be object")
    for field in ["mutationId", "commandRef", "mutationClass", "targetScope", "mode", "policyDecisionRef", "mutatedHost"]:
        require(field in mutation, f"mutationReceipt missing {field}")
    require(mutation["mode"] in {"dry-run", "live"}, "invalid mutation mode")
    if mutation["mutatedHost"]:
        require(mutation["mode"] == "live", "mutatedHost=true requires mode=live")
        require(mutation.get("humanControlEventRef"), "live host mutation requires human control event ref")

    approval = data.get("operatorApprovalReceipt")
    require(isinstance(approval, dict), "operatorApprovalReceipt must be object")
    for field in ["approvalId", "actorRef", "subjectRef", "decision", "policyGateRef", "agentplaneRunRef", "deliveryExcellenceEventRef"]:
        require(field in approval, f"operatorApprovalReceipt missing {field}")
    require(approval["decision"] in {"approved", "rejected", "deferred", "accepted-risk", "revoked"}, "invalid operator decision")


def main() -> int:
    try:
        data = load_json(EXAMPLE)
        validate(data)
    except (json.JSONDecodeError, ValidationError) as exc:
        print(f"TurtleTerm Agent Harness receipt validation failed: {exc}", file=sys.stderr)
        return 1
    print("OK: TurtleTerm Agent Harness receipt fixture validates")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
