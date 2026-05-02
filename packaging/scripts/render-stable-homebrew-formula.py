#!/usr/bin/env python3
"""Render the stable TurtleTerm Homebrew formula from a release tag.

Usage:
  python3 packaging/scripts/render-stable-homebrew-formula.py turtle-term-v0.1.0 <source_sha256>

The generated formula is written to:
  packaging/homebrew/Formula/turtle-term.rb
"""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "packaging" / "homebrew" / "templates" / "turtle-term.rb.template"
OUTPUT = ROOT / "packaging" / "homebrew" / "Formula" / "turtle-term.rb"


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: render-stable-homebrew-formula.py <tag> <source_sha256>", file=sys.stderr)
        return 2

    tag, source_sha256 = argv
    if not tag.startswith("turtle-term-v"):
        print("error: tag must start with turtle-term-v", file=sys.stderr)
        return 2
    if len(source_sha256) != 64 or any(ch not in "0123456789abcdefABCDEF" for ch in source_sha256):
        print("error: source_sha256 must be a 64-character hex digest", file=sys.stderr)
        return 2

    content = TEMPLATE.read_text(encoding="utf-8")
    content = content.replace("{{TAG}}", tag)
    content = content.replace("{{SOURCE_SHA256}}", source_sha256.lower())
    OUTPUT.write_text(content, encoding="utf-8")
    print(OUTPUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
