#!/usr/bin/env python3
"""Write a TurtleTerm release manifest for packaged artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description="write TurtleTerm release manifest")
    parser.add_argument("--version", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--archive", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    archive = Path(args.archive)
    if not archive.exists():
        raise SystemExit(f"archive not found: {archive}")

    manifest = {
        "schema": "sourceos.turtle-term.release.manifest.v0",
        "product": "TurtleTerm",
        "engine": "WezTerm",
        "version": args.version,
        "target": args.target,
        "archive": archive.name,
        "archive_sha256": sha256(archive),
        "license": "MIT",
        "upstream_attribution": "Built on the WezTerm engine; upstream WezTerm attribution and license are preserved.",
        "binaries": [
            "wezterm",
            "wezterm-gui",
            "wezterm-mux-server",
            "turtle-term",
            "sourceos-term",
        ],
        "profile": "etc/turtle-term/wezterm.lua",
        "docs": "share/turtle-term/sourceos",
        "install_validation": [
            "turtle-term paths",
            "turtle-term run -- echo turtle-term-ok",
            "sourceos-term paths",
        ],
    }

    out = Path(args.out)
    out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
