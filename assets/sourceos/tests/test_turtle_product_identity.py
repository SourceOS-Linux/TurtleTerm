#!/usr/bin/env python3
"""Product identity guardrails for TurtleTerm app metadata."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    desktop = read("assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop")
    metainfo = read("assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml")
    plist = read("assets/sourceos/macos/Info.plist")
    icon = read("assets/sourceos/brand/ai.sourceos.TurtleTerm.svg")
    package_script = read("packaging/scripts/package-turtle-term.sh")
    homebrew = read("packaging/homebrew/Formula/turtle-term.rb")

    assert "Name=TurtleTerm" in desktop
    assert "Exec=turtleterm %u" in desktop
    assert "Icon=ai.sourceos.TurtleTerm" in desktop
    assert "StartupWMClass=TurtleTerm" in desktop
    assert "org.wezfurlong" not in desktop

    assert "<id>ai.sourceos.TurtleTerm</id>" in metainfo
    assert "<name>TurtleTerm</name>" in metainfo
    assert "<binary>turtleterm</binary>" in metainfo
    assert "org.wezfurlong" not in metainfo

    assert "<string>TurtleTerm</string>" in plist
    assert "<string>ai.sourceos.TurtleTerm</string>" in plist
    assert "<string>turtleterm</string>" in plist
    assert "org.wezfurlong" not in plist

    assert "TurtleTerm" in icon
    assert "turtle" in icon.lower()

    assert "ai.sourceos.TurtleTerm.desktop" in package_script
    assert "ai.sourceos.TurtleTerm.metainfo.xml" in package_script
    assert "ai.sourceos.TurtleTerm.svg" in package_script
    assert "stage-macos-app.sh" in package_script

    assert "ai.sourceos.TurtleTerm.desktop" in homebrew
    assert "ai.sourceos.TurtleTerm.metainfo.xml" in homebrew
    assert "ai.sourceos.TurtleTerm.svg" in homebrew

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
