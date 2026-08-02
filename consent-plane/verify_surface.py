#!/usr/bin/env python3
"""Enforce this repo's consent-plane surface envelope (fail-closed).

Reads consent-plane/surface.yaml and asserts the hard invariants for its
surface_id, so CI FAILS if the surface's containment is weakened. Conforms to
socioprophet-agent-standards consent-plane/001 + sourceos-spec
isolation-spaces-and-taints. Proven both ways by consent-plane/self_test.py.
"""
from __future__ import annotations
import sys
from pathlib import Path
try:
    import yaml  # type: ignore
except Exception as exc:  # pragma: no cover
    raise SystemExit("PyYAML is required (pip install pyyaml)") from exc

# Minimum containment each surface MUST assert (subset checks).
EXPECTED = {
    "terminal": {"deny_purposes": {"egress", "operate"},
                 "space_deny": {"kernel-space", "system-space"}},
    "notes":    {"deny_purposes": {"egress", "operate"},
                 "space_deny": {"kernel-space", "system-space", "data-namespace"},
                 "consent_required": "per-purpose"},
    "browser":  {"deny_purposes": {"implement", "operate"},
                 "space_deny": {"kernel-space", "system-space", "user-space", "data-namespace"},
                 "untrusted_input": True},
}

def main() -> int:
    cfg = Path(__file__).resolve().parent / "surface.yaml"
    cp = yaml.safe_load(cfg.read_text()) or {}
    sid = cp.get("surface_id")
    errors: list[str] = []
    if sid not in EXPECTED:
        print(f"ERR: unknown surface_id {sid!r} (expected one of {sorted(EXPECTED)})", file=sys.stderr)
        return 1
    exp = EXPECTED[sid]
    for key, want in exp.items():
        got = cp.get(key)
        if isinstance(want, set):
            have = set(got or [])
            if not want <= have:
                errors.append(f"{key} must include {sorted(want)}; missing {sorted(want - have)}")
        else:
            if got != want:
                errors.append(f"{key} must be {want!r}, got {got!r}")
    if errors:
        print(f"FAIL: {sid} surface envelope violated:", file=sys.stderr)
        for e in errors: print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"OK: {sid} surface envelope holds ({', '.join(exp)}).")
    return 0

if __name__ == "__main__":
    sys.exit(main())
