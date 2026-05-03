#!/usr/bin/env python3
"""Verify a TurtleTerm release artifact, checksum, and manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import tarfile
from pathlib import Path


REQUIRED_BINARIES = {
    "wezterm",
    "wezterm-gui",
    "wezterm-mux-server",
    "turtle-term",
    "sourceos-term",
}

REQUIRED_TOP_LEVEL_SUFFIXES = {
    "LICENSE.md",
    "README.md",
    "UPSTREAM_WEZTERM_README.md",
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
    if manifest.get("engine") != "WezTerm":
        raise SystemExit("unexpected manifest engine")
    if manifest.get("archive") != archive.name:
        raise SystemExit("manifest archive name does not match")
    if manifest.get("archive_sha256") != archive_hash:
        raise SystemExit("manifest archive hash does not match")

    binaries = set(manifest.get("binaries", []))
    missing_manifest_bins = REQUIRED_BINARIES - binaries
    if missing_manifest_bins:
        raise SystemExit(f"manifest missing binaries: {sorted(missing_manifest_bins)}")

    members = archive_members(archive)
    for binary in REQUIRED_BINARIES:
        if not suffix_present(members, f"bin/{binary}"):
            raise SystemExit(f"archive missing binary: {binary}")

    for suffix in REQUIRED_TOP_LEVEL_SUFFIXES:
        if not suffix_present(members, suffix):
            raise SystemExit(f"archive missing {suffix}")

    if not suffix_present(members, "etc/turtle-term/wezterm.lua"):
        raise SystemExit("archive missing TurtleTerm profile")
    if not any("share/turtle-term/sourceos/" in member for member in members):
        raise SystemExit("archive missing SourceOS documentation")

    print(f"verified {archive.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
