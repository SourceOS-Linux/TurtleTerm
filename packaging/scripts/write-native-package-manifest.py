#!/usr/bin/env python3
"""Write TurtleTerm native Linux package manifests."""

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
    parser = argparse.ArgumentParser(description="write TurtleTerm native package manifest")
    parser.add_argument("--package", required=True)
    parser.add_argument("--kind", required=True, choices=["deb", "rpm", "arch"])
    parser.add_argument("--version", required=True)
    parser.add_argument("--arch", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    package = Path(args.package)
    if not package.exists():
        raise SystemExit(f"package not found: {package}")

    manifest = {
        "schema": "sourceos.turtle-term.native-package.manifest.v0",
        "product": "TurtleTerm",
        "kind": args.kind,
        "version": args.version,
        "arch": args.arch,
        "package": package.name,
        "package_sha256": sha256(package),
        "license": "MIT",
        "notices": "THIRD_PARTY_NOTICES.md",
        "public_commands": [
            "turtleterm",
            "turtleterm-mux-server",
            "turtle-term",
            "turtle-agentd",
            "turtle-agentctl",
            "turtle-agent-status",
            "turtle-tmux",
            "turtle-cloudfog",
            "turtle-superconscious",
            "turtle-agent-machine",
            "turtle-language",
            "turtle-session",
            "sourceos-term"
        ],
        "private_runtime_path": "libexec/turtle-term",
        "profile": "/etc/turtle-term/turtleterm.lua",
        "desktop_id": "ai.sourceos.TurtleTerm.desktop",
        "appstream_id": "ai.sourceos.TurtleTerm",
        "icon": "ai.sourceos.TurtleTerm.svg"
    }

    out = Path(args.out)
    out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
