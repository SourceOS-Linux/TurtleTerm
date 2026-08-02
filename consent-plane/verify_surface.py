#!/usr/bin/env python3
"""Enforce this repo's consent-plane surface envelope (fail-closed).

This repo IS the terminal surface; EXPECTED_SURFACE pins it so surface.yaml
cannot be silently switched to a weaker surface. Reads consent-plane/surface.yaml
and asserts the hard invariants. Proven both ways by consent-plane/self_test.py.
Conforms to socioprophet-agent-standards consent-plane/001 + sourceos-spec
isolation-spaces-and-taints.
"""
from __future__ import annotations
import sys
from pathlib import Path
try:
    import yaml  # type: ignore
except Exception as exc:  # pragma: no cover
    raise SystemExit("PyYAML is required (python -m pip install pyyaml)") from exc

EXPECTED_SURFACE = "terminal"

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


def check(cp: dict) -> list[str]:
    errors: list[str] = []
    sid = cp.get("surface_id")
    if sid != EXPECTED_SURFACE:
        return [f"surface_id must be {EXPECTED_SURFACE!r} for this repo, got {sid!r}"]
    for key, want in EXPECTED[sid].items():
        got = cp.get(key)
        if isinstance(want, set):
            if not isinstance(got, list):
                errors.append(f"{key} must be a list, got {type(got).__name__}")
                continue
            missing = want - set(got)
            if missing:
                errors.append(f"{key} must include {sorted(want)}; missing {sorted(missing)}")
        elif got != want:
            errors.append(f"{key} must be {want!r}, got {got!r}")
    return errors


def load() -> dict:
    cfg = Path(__file__).resolve().parent / "surface.yaml"
    cp = yaml.safe_load(cfg.read_text())
    if not isinstance(cp, dict):
        raise SystemExit("consent-plane/surface.yaml top-level must be a mapping")
    return cp


def main() -> int:
    errors = check(load())
    if errors:
        print(f"FAIL: {EXPECTED_SURFACE} surface envelope violated:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"OK: {EXPECTED_SURFACE} surface envelope holds.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
