#!/usr/bin/env python3
"""Guardrails for the TurtleTerm agentic integration plan."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

REQUIRED_DOCS = [
    "docs/sourceos/AGENTIC_INTEGRATION_PLAN.md",
    "docs/sourceos/A2A_MCP_ZEROTRUST_BRIDGE.md",
    "docs/sourceos/ACP_A2A_BRIDGE.md",
    "docs/sourceos/MCP_BRIDGE.md",
    "docs/sourceos/TMUX_BRIDGE.md",
    "docs/sourceos/NEOVIM_INTEGRATION.md",
    "docs/sourceos/VSCODE_EXTENSION.md",
    "docs/sourceos/AGENT_REGISTRY_BRIDGE.md",
    "docs/sourceos/POLICY_FABRIC_BRIDGE.md",
    "docs/sourceos/AGENTPLANE_BRIDGE.md",
    "docs/sourceos/BROWSER_HANDOFF.md",
]

REQUIRED_SKILLS = [
    "assets/sourceos/skills/turtle-terminal-inspector.json",
    "assets/sourceos/skills/turtle-terminal-executor.json",
    "assets/sourceos/skills/turtle-tmux-bridge.json",
    "assets/sourceos/skills/turtle-neovim-context.json",
    "assets/sourceos/skills/turtle-vscode-context.json",
    "assets/sourceos/skills/turtle-acp-ingress.json",
    "assets/sourceos/skills/turtle-mcp-bridge.json",
    "assets/sourceos/skills/turtle-a2a-gateway.json",
    "assets/sourceos/skills/turtle-policy-gate.json",
    "assets/sourceos/skills/turtle-agent-registry-client.json",
    "assets/sourceos/skills/turtle-agentplane-runner.json",
    "assets/sourceos/skills/turtle-bearbrowser-handoff.json",
]

FORBIDDEN_PLAN_PHRASES = [
    "build a new editor",
    "replace VS Code",
    "replace Zed",
    "replace JetBrains",
    "replace Neovim",
    "replace tmux",
    "raw shell over MCP",
    "ambient shell authority",
]

REQUIRED_PLAN_PHRASES = [
    "TurtleTerm is the trusted terminal/session execution layer",
    "Neovim is a first-class TurtleTerm integration target",
    "TurtleTerm plus Neovim should be enough",
    "ACP: editor/client-to-agent interface",
    "A2A: agent-to-agent delegation",
    "MCP: tool, context, prompt, and resource access",
    "Policy Fabric",
    "Agent Registry",
    "AgentPlane",
    "tmux bridge",
    "Neovim integration",
    "VS Code-compatible extension",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    for path in REQUIRED_DOCS:
        assert (ROOT / path).exists(), f"missing integration doc: {path}"

    for path in REQUIRED_SKILLS:
        skill_path = ROOT / path
        assert skill_path.exists(), f"missing skill manifest: {path}"
        data = json.loads(skill_path.read_text(encoding="utf-8"))
        assert data["type"] == "SkillManifest"
        assert data["specVersion"] == "2.0.0"
        assert data["id"].startswith("urn:srcos:skill:turtle-")
        assert isinstance(data.get("policyBindings"), list) and data["policyBindings"], path
        assert "allowShellExecution" in data, path
        assert "reviewMode" in data, path

    plan = read("docs/sourceos/AGENTIC_INTEGRATION_PLAN.md")
    lowered = plan.lower()
    for phrase in REQUIRED_PLAN_PHRASES:
        assert phrase in plan, f"missing required plan phrase: {phrase}"
    for phrase in FORBIDDEN_PLAN_PHRASES:
        assert phrase not in lowered, f"forbidden phrase present: {phrase}"

    neovim = read("docs/sourceos/NEOVIM_INTEGRATION.md")
    assert "Neovim is a first-class TurtleTerm integration target" in neovim
    assert "TurtleTerm plus Neovim should be sufficient" in neovim
    assert "thin client over `turtle-agentd`" in neovim
    assert "raw shell execution from plugin code" in neovim

    acp = read("docs/sourceos/ACP_A2A_BRIDGE.md")
    assert "ACP is the editor/client ingress" in acp
    assert "A2A" in acp
    assert "Policy Fabric" in acp

    zerotrust = read("docs/sourceos/A2A_MCP_ZEROTRUST_BRIDGE.md")
    assert "MCP tools cannot directly execute shell commands" in zerotrust
    assert "A2A delegates only to registered agents" in zerotrust
    assert "ACP requests cannot bypass policy" in zerotrust

    browser = read("docs/sourceos/BROWSER_HANDOFF.md")
    assert "TurtleTerm does not own browser automation" in browser
    assert "BearBrowser" in browser
    assert "Stagehand" in browser
    assert "Playwright" in browser

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
