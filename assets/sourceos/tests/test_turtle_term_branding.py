#!/usr/bin/env python3
"""Brand and packaging guardrails for TurtleTerm."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

PRODUCT_SURFACES = [
    "README.md",
    "docs/sourceos/INSTALL.md",
    "packaging/homebrew/README.md",
    "packaging/homebrew/Formula/turtle-term.rb",
    "packaging/homebrew/templates/turtle-term.rb.template",
]

FORBIDDEN_PRODUCT_SURFACE_TERMS = [
    "built on the back of WezTerm",
    "WezTerm engine",
    "SourceOS WezTerm profile",
    "upstream terminal emulator",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    readme = read("README.md")
    formula = read("packaging/homebrew/Formula/turtle-term.rb")
    template = read("packaging/homebrew/templates/turtle-term.rb.template")
    install = read("docs/sourceos/INSTALL.md")
    packaging_readme = read("packaging/homebrew/README.md")
    notices = read("THIRD_PARTY_NOTICES.md")

    assert "They say the world was built on the back of a turtle" in readme
    assert "TurtleTerm carries the shell on its back" in readme
    assert "brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/homebrew/Formula/turtle-term.rb" in readme
    assert "turtleterm" in readme
    assert "TurtleTerm turtle icon" in readme

    assert "class TurtleTerm < Formula" in formula
    assert "class TurtleTerm < Formula" in template
    assert "desc \"TurtleTerm: SourceOS policy-aware agent terminal fabric\"" in formula
    assert "To launch TurtleTerm:" in formula
    assert "turtleterm" in formula
    assert "turtleterm.lua" in formula
    assert "turtleterm.lua" in template
    assert "TurtleTerm command wrapper" in formula
    assert "TurtleTerm command wrapper" in template

    assert "brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/homebrew/Formula/turtle-term.rb" in install
    assert "Then launch TurtleTerm:" in install
    assert "turtleterm.lua" in install
    assert "Windows packaging is postponed" in install

    assert "turtleterm.lua" in packaging_readme
    assert "Private terminal runtime binaries" in packaging_readme

    assert "WezTerm" in notices
    assert "Third-Party Notices" in notices

    for path in PRODUCT_SURFACES:
        content = read(path)
        for term in FORBIDDEN_PRODUCT_SURFACE_TERMS:
            assert term not in content, f"product surface {path} leaked forbidden term: {term}"

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
