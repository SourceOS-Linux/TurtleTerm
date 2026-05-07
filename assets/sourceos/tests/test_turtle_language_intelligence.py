#!/usr/bin/env python3
"""Smoke tests for TurtleTerm language intelligence."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
LANGUAGE = ROOT / "assets" / "sourceos" / "bin" / "turtle-language"


def run(args: list[str]) -> dict:
    result = subprocess.run(
        [sys.executable, str(LANGUAGE), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    assert result.returncode == 0, result.stderr or result.stdout
    return json.loads(result.stdout)


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        good = root / "good.py"
        good.write_text("class Greeter:\n    def hello(self):\n        return 'world'\n", encoding="utf-8")
        bad = root / "bad.py"
        bad.write_text("def broken(:\n    pass\n", encoding="utf-8")

        diagnostics = run(["diagnostics", str(good)])
        assert diagnostics["kind"] == "diagnostics"
        assert diagnostics["data"]["diagnostics"] == []
        assert diagnostics["data"]["mutationAllowed"] is False

        bad_diagnostics = run(["diagnostics", str(bad)])
        assert bad_diagnostics["kind"] == "diagnostics"
        assert bad_diagnostics["data"]["diagnostics"][0]["severity"] == "error"

        symbols = run(["symbols", str(good)])
        assert symbols["kind"] == "symbols"
        names = {symbol["name"] for symbol in symbols["data"]["symbols"]}
        assert "Greeter" in names
        assert "hello" in names

        explanation = run(["explain-selection", str(good), "--start", "1", "--end", "2"])
        assert explanation["kind"] == "explanation"
        assert explanation["data"]["mutationAllowed"] is False

        proposal = run(["propose-patch", str(good), "--prompt", "make safer"])
        assert proposal["kind"] == "patch_proposal"
        assert proposal["data"]["mutationAllowed"] is False
        assert proposal["data"]["proposal"]["status"] == "deferred"

        index = run(["index", str(root)])
        assert index["kind"] == "index"
        indexed_paths = {item["path"] for item in index["data"]["files"]}
        assert "good.py" in indexed_paths
        assert "bad.py" in indexed_paths

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
