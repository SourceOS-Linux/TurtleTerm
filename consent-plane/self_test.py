#!/usr/bin/env python3
"""Prove verify_surface fires both ways: passes on the real envelope, fires when
the containment is weakened or the surface_id is switched."""
from __future__ import annotations
import copy, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_surface as v  # noqa: E402

cp = v.load()
assert v.check(cp) == [], f"real envelope should pass: {v.check(cp)}"

if cp.get("space_deny"):
    weak = copy.deepcopy(cp); weak["space_deny"] = weak["space_deny"][:-1]
    assert v.check(weak), "verifier did not fire on a weakened space_deny"

switched = copy.deepcopy(cp)
switched["surface_id"] = "browser" if cp["surface_id"] != "browser" else "terminal"
assert v.check(switched), "verifier did not fire on a switched surface_id"

print("OK: verify_surface fires both ways (holds on real; catches weakening + switch).")
