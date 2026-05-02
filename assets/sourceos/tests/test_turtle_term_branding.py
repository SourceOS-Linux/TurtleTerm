#!/usr/bin/env python3
"""Brand and packaging guardrails for TurtleTerm."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    readme = read("README.md")
    formula = read("packaging/homebrew/Formula/turtle-term.rb")
    template = read("packaging/homebrew/templates/turtle-term.rb.template")
    install = read("docs/sourceos/INSTALL.md")

    assert "They say the world was built on the back of a turtle" in readme
    assert "TurtleTerm is built on the back of WezTerm" in readme
    assert "brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/wezterm/main/packaging/homebrew/Formula/turtle-term.rb" in readme

    assert "class TurtleTerm < Formula" in formula
    assert "class TurtleTerm < Formula" in template
    assert "turtle-term run -- echo hello" in formula
    assert "TurtleTerm command wrapper" in formula
    assert "TurtleTerm command wrapper" in template

    assert "brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/wezterm/main/packaging/homebrew/Formula/turtle-term.rb" in install
    assert "Windows packaging is postponed" in install

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
