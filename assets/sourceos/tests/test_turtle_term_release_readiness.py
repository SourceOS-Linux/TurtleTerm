#!/usr/bin/env python3
"""Release-readiness guardrails for TurtleTerm distribution."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

REQUIRED_FILES = [
    "README.md",
    "LICENSE.md",
    "docs/sourceos/INSTALL.md",
    "docs/sourceos/PACKAGING.md",
    "docs/sourceos/RELEASE_CHECKLIST.md",
    "docs/sourceos/SESSION_CONTRACT.md",
    "docs/sourceos/UPSTREAM_SYNC.md",
    "assets/sourceos/bin/turtle-term",
    "assets/sourceos/bin/sourceos-term",
    "assets/sourceos/wezterm.lua",
    "assets/sourceos/tests/test_sourceos_term_smoke.py",
    "assets/sourceos/tests/test_turtle_term_branding.py",
    "assets/sourceos/tests/test_turtle_term_release_readiness.py",
    "packaging/homebrew/Formula/turtle-term.rb",
    "packaging/homebrew/templates/turtle-term.rb.template",
    "packaging/homebrew/README.md",
    "packaging/homebrew/TAP_HANDOFF.md",
    "packaging/scripts/install-turtle-term.sh",
    "packaging/scripts/package-turtle-term.sh",
    "packaging/scripts/bootstrap-homebrew-tap.sh",
    "packaging/scripts/render-stable-homebrew-formula.py",
    "packaging/scripts/write-turtle-term-manifest.py",
    ".github/workflows/turtle-term-release.yml",
    ".github/workflows/turtle-term-homebrew.yml",
    ".github/workflows/turtle-term-scripts.yml",
    ".github/workflows/turtle-term-sync-homebrew-tap.yml",
    ".github/workflows/turtle-term-promote-homebrew-stable.yml",
]

FORBIDDEN_FILES = [
    "packaging/homebrew/Formula/sourceos-wezterm.rb",
]

REQUIRED_README_SNIPPETS = [
    "TurtleTerm is built on the back of WezTerm",
    "brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/wezterm/main/packaging/homebrew/Formula/turtle-term.rb",
    "brew install SourceOS-Linux/tap/turtle-term",
    "turtle-term run -- echo hello",
]

REQUIRED_FORMULA_SNIPPETS = [
    "class TurtleTerm < Formula",
    "desc \"TurtleTerm:",
    "bin.install \"target/release/wezterm\"",
    "bin.install \"assets/sourceos/bin/turtle-term\"",
    "etc.install \"assets/sourceos/wezterm.lua\" => \"turtle-term/wezterm.lua\"",
    "assert_match \"TurtleTerm command wrapper\"",
]

REQUIRED_RELEASE_WORKFLOW_SNIPPETS = [
    "turtle-term-v*",
    "macos-arm64",
    "macos-x86_64",
    "linux-x86_64",
    "linux-arm64",
    "softprops/action-gh-release",
    "turtle-term-*.tar.gz.manifest.json",
]

REQUIRED_PACKAGE_SCRIPT_SNIPPETS = [
    "write-turtle-term-manifest.py",
    "--version",
    "--target",
    "--archive",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def assert_contains(path: str, snippets: list[str]) -> None:
    content = read(path)
    for snippet in snippets:
        assert snippet in content, f"missing {snippet!r} in {path}"


def main() -> int:
    for path in REQUIRED_FILES:
        assert (ROOT / path).exists(), f"required file missing: {path}"

    for path in FORBIDDEN_FILES:
        assert not (ROOT / path).exists(), f"forbidden stale file present: {path}"

    assert_contains("README.md", REQUIRED_README_SNIPPETS)
    assert_contains("packaging/homebrew/Formula/turtle-term.rb", REQUIRED_FORMULA_SNIPPETS)
    assert_contains(".github/workflows/turtle-term-release.yml", REQUIRED_RELEASE_WORKFLOW_SNIPPETS)
    assert_contains("packaging/scripts/package-turtle-term.sh", REQUIRED_PACKAGE_SCRIPT_SNIPPETS)

    install = read("docs/sourceos/INSTALL.md")
    assert "Windows packaging is postponed" in install
    assert "TURTLE_TERM_VERSION=turtle-term-v0.1.0" in install

    checklist = read("docs/sourceos/RELEASE_CHECKLIST.md")
    assert "macOS ARM64" in checklist
    assert "macOS Intel" in checklist
    assert "Linux x86_64" in checklist
    assert "Linux ARM64" in checklist
    assert "manifest" in checklist.lower()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
