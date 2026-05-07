#!/usr/bin/env python3
"""Release-readiness guardrails for TurtleTerm distribution."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]

REQUIRED_FILES = [
    "README.md",
    "LICENSE.md",
    "THIRD_PARTY_NOTICES.md",
    "docs/sourceos/INSTALL.md",
    "docs/sourceos/PACKAGING.md",
    "docs/sourceos/RELEASE_CHECKLIST.md",
    "docs/sourceos/SESSION_CONTRACT.md",
    "docs/sourceos/SUPPLY_CHAIN.md",
    "docs/sourceos/UPSTREAM_SYNC.md",
    "docs/sourceos/LANGUAGE_INTELLIGENCE.md",
    "assets/sourceos/brand/turtleterm-icon.svg",
    "assets/sourceos/brand/ai.sourceos.TurtleTerm.svg",
    "assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop",
    "assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml",
    "assets/sourceos/bin/turtleterm",
    "assets/sourceos/bin/turtleterm-mux-server",
    "assets/sourceos/bin/turtle-term",
    "assets/sourceos/bin/sourceos-term",
    "assets/sourceos/bin/turtle-agentd",
    "assets/sourceos/bin/turtle-agentctl",
    "assets/sourceos/bin/turtle-tmux",
    "assets/sourceos/bin/turtle-cloudfog",
    "assets/sourceos/bin/turtle-superconscious",
    "assets/sourceos/bin/turtle-agent-machine",
    "assets/sourceos/bin/turtle-language",
    "assets/sourceos/skills/turtle-language-context.json",
    "assets/sourceos/turtleterm.lua",
    "assets/sourceos/tests/test_sourceos_term_smoke.py",
    "assets/sourceos/tests/test_turtle_bridge_features.py",
    "assets/sourceos/tests/test_turtle_language_intelligence.py",
    "assets/sourceos/tests/test_turtle_term_branding.py",
    "assets/sourceos/tests/test_turtle_term_release_readiness.py",
    "assets/sourceos/tests/test_turtle_agentic_integration_plan.py",
    "assets/sourceos/tests/test_turtle_linux_native_packaging.py",
    "packaging/homebrew/Formula/turtle-term.rb",
    "packaging/homebrew/templates/turtle-term.rb.template",
    "packaging/homebrew/README.md",
    "packaging/homebrew/TAP_HANDOFF.md",
    "packaging/linux/README.md",
    "packaging/linux/deb/control",
    "packaging/linux/rpm/turtle-term.spec",
    "packaging/linux/arch/PKGBUILD",
    "packaging/scripts/install-turtle-term.sh",
    "packaging/scripts/package-turtle-term.sh",
    "packaging/scripts/stage-linux-package.sh",
    "packaging/scripts/build-deb-package.sh",
    "packaging/scripts/verify-deb-package.sh",
    "packaging/scripts/build-rpm-package.sh",
    "packaging/scripts/verify-rpm-package.sh",
    "packaging/scripts/build-arch-package.sh",
    "packaging/scripts/verify-arch-package.sh",
    "packaging/scripts/write-native-package-manifest.py",
    "packaging/scripts/bootstrap-homebrew-tap.sh",
    "packaging/scripts/render-stable-homebrew-formula.py",
    "packaging/scripts/write-turtle-term-manifest.py",
    "packaging/scripts/verify-turtle-term-artifact.py",
    ".github/workflows/turtle-term-release.yml",
    ".github/workflows/turtle-term-homebrew.yml",
    ".github/workflows/turtle-term-scripts.yml",
    ".github/workflows/turtle-term-linux-packaging.yml",
    ".github/workflows/turtle-term-native-linux-packages.yml",
    ".github/workflows/turtle-term-sync-homebrew-tap.yml",
    ".github/workflows/turtle-term-promote-homebrew-stable.yml",
]

FORBIDDEN_FILES = [
    "packaging/homebrew/Formula/sourceos-wezterm.rb",
]

REQUIRED_README_SNIPPETS = [
    "TurtleTerm carries the shell on its back",
    "brew install --HEAD https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/packaging/homebrew/Formula/turtle-term.rb",
    "brew install SourceOS-Linux/tap/turtle-term",
    "turtleterm",
    "TurtleTerm turtle icon",
]

REQUIRED_FORMULA_SNIPPETS = [
    "class TurtleTerm < Formula",
    "desc \"TurtleTerm: SourceOS policy-aware agent terminal fabric\"",
    "libexec/\"turtle-term\"",
    "turtleterm",
    "turtleterm.lua",
    "turtle-cloudfog",
    "turtle-superconscious",
    "turtle-agent-machine",
    "turtle-language",
    "ai.sourceos.TurtleTerm.desktop",
    "ai.sourceos.TurtleTerm.metainfo.xml",
    "ai.sourceos.TurtleTerm.svg",
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
    "anchore/sbom-action",
    "actions/attest@v4",
]

REQUIRED_NATIVE_WORKFLOW_SNIPPETS = [
    "turtle-term_*.deb",
    "turtle-term-*.rpm",
    "turtle-term-*.pkg.tar.zst",
    "turtle-term-native-packages.index.json",
    "actions/attest@v4",
]

REQUIRED_PACKAGE_SCRIPT_SNIPPETS = [
    "write-turtle-term-manifest.py",
    "libexec/turtle-term",
    "turtleterm",
    "turtleterm.lua",
    "turtle-cloudfog",
    "turtle-superconscious",
    "turtle-agent-machine",
    "turtle-language",
    "share/applications",
    "share/metainfo",
    "share/icons/hicolor/scalable/apps",
    "ai.sourceos.TurtleTerm.desktop",
    "ai.sourceos.TurtleTerm.metainfo.xml",
    "ai.sourceos.TurtleTerm.svg",
    "THIRD_PARTY_NOTICES.md",
]

REQUIRED_SUPPLY_CHAIN_SNIPPETS = [
    "GitHub artifact attestations",
    "SPDX JSON SBOM",
    "verify-turtle-term-artifact.py",
    "turtle-term-<version>-<target>.tar.gz.manifest.json",
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
    assert_contains(".github/workflows/turtle-term-native-linux-packages.yml", REQUIRED_NATIVE_WORKFLOW_SNIPPETS)
    assert_contains("packaging/scripts/package-turtle-term.sh", REQUIRED_PACKAGE_SCRIPT_SNIPPETS)
    assert_contains("docs/sourceos/SUPPLY_CHAIN.md", REQUIRED_SUPPLY_CHAIN_SNIPPETS)

    install = read("docs/sourceos/INSTALL.md")
    assert "Windows packaging is postponed" in install
    assert "TURTLE_TERM_VERSION=turtle-term-v0.1.0" in install
    assert "Then launch TurtleTerm:" in install
    assert "turtleterm.lua" in install

    checklist = read("docs/sourceos/RELEASE_CHECKLIST.md")
    assert "macOS ARM64" in checklist
    assert "macOS Intel" in checklist
    assert "Linux x86_64" in checklist
    assert "Linux ARM64" in checklist
    assert "manifest" in checklist.lower()

    language = read("docs/sourceos/LANGUAGE_INTELLIGENCE.md")
    assert "turtle-language" in language
    assert "TurtleDiagnostics" in language
    assert "Tree-sitter" in language
    assert "LSP" in language

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
