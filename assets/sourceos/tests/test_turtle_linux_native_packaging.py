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
    stage = read("packaging/scripts/stage-linux-package.sh")
    rpm_builder = read("packaging/scripts/build-rpm-package.sh")

    assert "Package: turtle-term" in deb
    assert "Architecture: amd64 arm64" in deb
    assert "Homepage: https://github.com/SourceOS-Linux/TurtleTerm" in deb
    assert "libexec/turtle-term" in deb

    assert "Name:           turtle-term" in rpm
    assert "ExclusiveArch:  x86_64 aarch64" in rpm
    assert "fontconfig-devel" in rpm
    assert "ai.sourceos.TurtleTerm.desktop" in rpm

    assert "pkgname=turtle-term" in arch
    assert "arch=('x86_64' 'aarch64')" in arch
    assert "TURTLE_TERM_STAGE_PREFIX" in arch

    assert "TURTLE_TERM_STAGE_PREFIX" in stage
    assert "libexec/turtle-term" in stage
    assert "share/applications" in stage
    assert "share/metainfo" in stage
    assert "turtleterm.lua" in stage

    assert "%install" in rpm_builder
    assert "TURTLE_TERM_STAGE_PREFIX=%{buildroot}/usr" in rpm_builder
    assert "TURTLE_TERM_ETC_DIR=%{buildroot}/etc" in rpm_builder

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
