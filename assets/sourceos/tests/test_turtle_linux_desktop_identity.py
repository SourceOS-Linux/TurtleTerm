#!/usr/bin/env python3
"""Linux desktop identity checks for TurtleTerm."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    desktop = read("assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop")
    appstream = read("assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml")
    formula = read("packaging/homebrew/Formula/turtle-term.rb")
    package_script = read("packaging/scripts/package-turtle-term.sh")
    verifier = read("packaging/scripts/verify-turtle-term-artifact.py")

    assert "Name=TurtleTerm" in desktop
    assert "Exec=turtleterm %u" in desktop
    assert "Icon=ai.sourceos.TurtleTerm" in desktop
    assert "StartupWMClass=TurtleTerm" in desktop
    assert "Terminal=false" in desktop

    assert "<id>ai.sourceos.TurtleTerm</id>" in appstream
    assert "<name>TurtleTerm</name>" in appstream
    assert "<binary>turtleterm</binary>" in appstream

    assert "share/\"applications\"" in formula
    assert "share/\"metainfo\"" in formula
    assert "share/\"icons/hicolor/scalable/apps\"" in formula

    assert "share/applications" in package_script
    assert "share/metainfo" in package_script
    assert "share/icons/hicolor/scalable/apps" in package_script

    assert "REQUIRED_DESKTOP_SUFFIXES" in verifier
    assert "ai.sourceos.TurtleTerm.desktop" in verifier
    assert "ai.sourceos.TurtleTerm.metainfo.xml" in verifier
    assert "ai.sourceos.TurtleTerm.svg" in verifier

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
