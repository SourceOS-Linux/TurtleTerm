#!/usr/bin/env python3
"""Guardrails for TurtleTerm Neovim integration."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    spec = read("docs/sourceos/NEOVIM_INTEGRATION.md")
    readme = read("integrations/neovim/turtle.nvim/README.md")
    plugin = read("integrations/neovim/turtle.nvim/plugin/turtle.lua")
    client = read("integrations/neovim/turtle.nvim/lua/turtle.lua")
    skill = read("assets/sourceos/skills/turtle-neovim-context.json")

    assert "Neovim is a first-class TurtleTerm integration target" in spec
    assert "turtle.nvim" in readme
    assert "TurtlePing" in plugin
    assert "TurtleRequestExecution" in plugin
    assert "TurtleSurfaces" in plugin
    assert "TurtleCloudFogSurfaces" in plugin
    assert "TurtleSuperconsciousObserve" in plugin
    assert "TurtleAgentMachineSurfaces" in plugin
    assert "turtle-agentctl" in client
    assert "request-execution" in client
    assert "request-surface-execution" in client
    assert "cloudfog-surfaces" in client
    assert "superconscious-observe" in client
    assert "agent-machine-surfaces" in client
    assert "turtle-neovim-context" in skill
    assert "allowShellExecution" in skill

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
