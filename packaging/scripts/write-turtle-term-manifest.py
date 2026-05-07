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
        "version": args.version,
        "target": args.target,
        "archive": archive.name,
        "archive_sha256": sha256(archive),
        "license": "MIT",
        "notices": "THIRD_PARTY_NOTICES.md",
        "runtime": "private-terminal-runtime",
        "public_commands": [
            "turtleterm",
            "turtleterm-mux-server",
            "turtle-term",
            "turtle-agentd",
            "turtle-agentctl",
            "turtle-tmux",
            "turtle-cloudfog",
            "turtle-superconscious",
            "turtle-agent-machine",
            "turtle-language",
            "sourceos-term"
        ],
        "private_runtime_path": "libexec/turtle-term",
        "profile": "etc/turtle-term/turtleterm.lua",
        "docs": "share/turtle-term/sourceos",
        "skills": "share/turtle-term/skills",
        "brand": "share/turtle-term/brand",
        "install_validation": [
            "turtleterm --version || true",
            "turtle-term paths",
            "turtle-term run -- echo turtle-term-ok",
            "turtle-agentctl --stdio ping",
            "turtle-agentctl --stdio surfaces",
            "turtle-cloudfog surfaces",
            "turtle-superconscious observe hello",
            "turtle-agent-machine surfaces",
            "turtle-language diagnostics README.md"
        ],
    }

    out = Path(args.out)
    out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
