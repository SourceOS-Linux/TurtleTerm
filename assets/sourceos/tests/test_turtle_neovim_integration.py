#!/usr/bin/env python3
"""Guardrails for TurtleTerm Neovim integration."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    spec = read("docs/sourceos/NEOVIM_INTEGRATION.md")
    language_spec = read("docs/sourceos/LANGUAGE_INTELLIGENCE.md")
    readme = read("integrations/neovim/turtle.nvim/README.md")
    plugin = read("integrations/neovim/turtle.nvim/plugin/turtle.lua")
    client = read("integrations/neovim/turtle.nvim/lua/turtle.lua")
    skill = read("assets/sourceos/skills/turtle-neovim-context.json")
    language_skill = read("assets/sourceos/skills/turtle-language-context.json")

    assert "Neovim is a first-class TurtleTerm integration target" in spec
    assert "TurtleDiagnostics" in language_spec
    assert "turtle.nvim" in readme
    assert "TurtlePing" in plugin
    assert "TurtleRequestExecution" in plugin
    assert "TurtleSurfaces" in plugin
    assert "TurtleDiagnostics" in plugin
    assert "TurtleSymbols" in plugin
    assert "TurtleExplainSelection" in plugin
    assert "TurtleProposePatch" in plugin
    assert "TurtleIndex" in plugin
    assert "TurtleCloudFogSurfaces" in plugin
    assert "TurtleSuperconsciousObserve" in plugin
    assert "TurtleAgentMachineSurfaces" in plugin
    assert "turtle-agentctl" in client
    assert "turtle-language" in client
    assert "diagnostics" in client
    assert "symbols" in client
    assert "explain-selection" in client
    assert "propose-patch" in client
    assert "request-execution" in client
    assert "request-surface-execution" in client
    assert "cloudfog-surfaces" in client
    assert "superconscious-observe" in client
    assert "agent-machine-surfaces" in client
    assert "turtle-neovim-context" in skill
    assert "turtle-language-context" in language_skill
    assert "allowShellExecution" in skill
    assert "allowShellExecution" in language_skill

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
