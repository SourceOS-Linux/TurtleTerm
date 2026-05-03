#!/usr/bin/env python3
"""Verify a TurtleTerm release artifact, checksum, and manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import tarfile
from pathlib import Path


REQUIRED_PUBLIC_COMMANDS = {
    "turtleterm",
    "turtleterm-mux-server",
    "turtle-term",
    "turtle-agentd",
    "turtle-agentctl",
    "turtle-tmux",
    "sourceos-term",
}

REQUIRED_PRIVATE_RUNTIME = {
    "wezterm",
    "wezterm-gui",
    "wezterm-mux-server",
}

REQUIRED_TOP_LEVEL_SUFFIXES = {
    "LICENSE.md",
    "README.md",
    "THIRD_PARTY_NOTICES.md",
}

REQUIRED_DESKTOP_SUFFIXES = {
    "share/applications/ai.sourceos.TurtleTerm.desktop",
    "share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml",
    "share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_checksum(path: Path) -> str:
    text = path.read_text(encoding="utf-8").strip()
    return text.split()[0]


def archive_members(path: Path) -> set[str]:
    with tarfile.open(path, "r:gz") as tar:
        return set(tar.getnames())


def suffix_present(members: set[str], suffix: str) -> bool:
    return any(member.endswith("/" + suffix) or member == suffix for member in members)


def main() -> int:
    parser = argparse.ArgumentParser(description="verify TurtleTerm release artifact")
    parser.add_argument("archive")
    parser.add_argument("--checksum")
    parser.add_argument("--manifest")
    args = parser.parse_args()

    archive = Path(args.archive)
    checksum = Path(args.checksum) if args.checksum else archive.with_suffix(archive.suffix + ".sha256")
    manifest_path = Path(args.manifest) if args.manifest else Path(str(archive) + ".manifest.json")

    if not archive.exists():
        raise SystemExit(f"archive missing: {archive}")
    if not checksum.exists():
        raise SystemExit(f"checksum missing: {checksum}")
    if not manifest_path.exists():
        raise SystemExit(f"manifest missing: {manifest_path}")

    archive_hash = sha256(archive)
    expected_hash = read_checksum(checksum)
    if archive_hash != expected_hash:
        raise SystemExit(f"checksum mismatch: {archive_hash} != {expected_hash}")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schema") != "sourceos.turtle-term.release.manifest.v0":
        raise SystemExit("unexpected manifest schema")
    if manifest.get("product") != "TurtleTerm":
        raise SystemExit("unexpected manifest product")
    if manifest.get("archive") != archive.name:
        raise SystemExit("manifest archive name does not match")
    if manifest.get("archive_sha256") != archive_hash:
        raise SystemExit("manifest archive hash does not match")
    if manifest.get("runtime") != "private-terminal-runtime":
        raise SystemExit("manifest runtime must be private-terminal-runtime")
    if manifest.get("profile") != "etc/turtle-term/turtleterm.lua":
        raise SystemExit("manifest must point at TurtleTerm product profile")

    public_commands = set(manifest.get("public_commands", []))
    missing_commands = REQUIRED_PUBLIC_COMMANDS - public_commands
    if missing_commands:
        raise SystemExit(f"manifest missing public commands: {sorted(missing_commands)}")

    members = archive_members(archive)
    for command in REQUIRED_PUBLIC_COMMANDS:
        if not suffix_present(members, f"bin/{command}"):
            raise SystemExit(f"archive missing public command: {command}")

    for runtime in REQUIRED_PRIVATE_RUNTIME:
        if not suffix_present(members, f"libexec/turtle-term/{runtime}"):
            raise SystemExit(f"archive missing private runtime binary: {runtime}")
        if suffix_present(members, f"bin/{runtime}"):
            raise SystemExit(f"private runtime binary exposed on product PATH: {runtime}")

    for suffix in REQUIRED_TOP_LEVEL_SUFFIXES:
        if not suffix_present(members, suffix):
            raise SystemExit(f"archive missing {suffix}")

    for suffix in REQUIRED_DESKTOP_SUFFIXES:
        if not suffix_present(members, suffix):
            raise SystemExit(f"archive missing desktop metadata: {suffix}")

    if not suffix_present(members, "etc/turtle-term/turtleterm.lua"):
        raise SystemExit("archive missing TurtleTerm product profile")
    if not any("share/turtle-term/sourceos/" in member for member in members):
        raise SystemExit("archive missing SourceOS documentation")
    if not any("share/turtle-term/skills/" in member for member in members):
        raise SystemExit("archive missing TurtleTerm skill manifests")
    if not any("share/turtle-term/brand/" in member for member in members):
        raise SystemExit("archive missing TurtleTerm brand assets")
    if not any("share/turtle-term/desktop/" in member for member in members):
        raise SystemExit("archive missing TurtleTerm desktop source metadata")

    print(f"verified {archive.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
