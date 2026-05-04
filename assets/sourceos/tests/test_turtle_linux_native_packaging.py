#!/usr/bin/env python3
"""Linux native packaging guardrails for TurtleTerm."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    deb = read("packaging/linux/deb/control")
    rpm = read("packaging/linux/rpm/turtle-term.spec")
    arch = read("packaging/linux/arch/PKGBUILD")

    assert "Package: turtle-term" in deb
    assert "TurtleTerm trusted terminal" in deb
    assert "Homepage: https://github.com/SourceOS-Linux/TurtleTerm" in deb

    assert "Name:           turtle-term" in rpm
    assert "Summary:        TurtleTerm trusted terminal" in rpm
    assert "ai.sourceos.TurtleTerm.desktop" in rpm
    assert "ai.sourceos.TurtleTerm.metainfo.xml" in rpm
    assert "ai.sourceos.TurtleTerm.svg" in rpm

    assert "pkgname=turtle-term" in arch
    assert "TurtleTerm trusted terminal" in arch
    assert "ai.sourceos.TurtleTerm.desktop" in arch
    assert "ai.sourceos.TurtleTerm.metainfo.xml" in arch
    assert "ai.sourceos.TurtleTerm.svg" in arch

    forbidden = ["sourceos-linux/wezterm", "org.wezfurlong"]
    for content in (deb, rpm, arch):
        lowered = content.lower()
        for value in forbidden:
            assert value not in lowered, value

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
