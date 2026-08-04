#!/usr/bin/env python3
"""Regression coverage for turtle-language symbol merge under a flaky LSP.

When the SynapseIQ LSP is reachable, `turtle-language symbols` merges the LSP
result with the local AST walk. CI has no LSP, so that merge path is otherwise
never exercised — this test drives it directly with malformed LSP payloads that
a real server can return (null symbols, scalar entries, null line numbers) and
asserts the command neither crashes nor drops a local symbol.
"""
import importlib.machinery
import importlib.util
import sys
import tempfile
from pathlib import Path

BIN = Path(__file__).resolve().parents[1] / "bin" / "turtle-language"


def _load():
    loader = importlib.machinery.SourceFileLoader("turtle_language_mod", str(BIN))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


def _symbols_with_lsp(mod, payload):
    mod.ensure_synapseiq = lambda: None
    mod.synapseiq_symbols = lambda *a, **k: payload
    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as fh:
        fh.write("class Greeter:\n    def hello(self):\n        return 1\n")
        p = Path(fh.name)
    try:
        return mod.symbols(p)
    finally:
        p.unlink(missing_ok=True)


def main() -> int:
    mod = _load()
    names = lambda res: {s.get("name") for s in res["symbols"]}

    # 1. null "symbols" must not crash; local symbols survive.
    r = _symbols_with_lsp(mod, {"symbols": None})
    assert "Greeter" in names(r) and "hello" in names(r), r

    # 2. non-dict entries are filtered, not fatal.
    r = _symbols_with_lsp(mod, {"symbols": ["junk", 42, {"name": "Greeter", "line": 1}]})
    assert "hello" in names(r), r

    # 3. a present-but-null line must not blow up the sort.
    r = _symbols_with_lsp(mod, {"symbols": [{"name": "Greeter", "line": None}]})
    assert "hello" in names(r), r

    # 4. a top-level LSP symbol sharing a method's name must NOT drop the method.
    r = _symbols_with_lsp(mod, {"symbols": [{"name": "hello", "line": 99}]})
    hello_lines = sorted(s.get("line") for s in r["symbols"] if s.get("name") == "hello")
    assert len(hello_lines) == 2, f"method dropped by name-only dedup: {r['symbols']}"

    # 5. non-dict top-level payload falls back to the builtin heuristic cleanly.
    r = _symbols_with_lsp(mod, ["not", "a", "dict"])
    assert r["source"] == "builtin-heuristic" and "hello" in names(r), r

    print("turtle-language symbol merge: 5/5 robustness checks pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
