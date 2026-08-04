# Preflight — make a local "green" mean what CI's green means

```sh
make preflight        # or: bash packaging/scripts/preflight.sh
```

## Why this exists

TurtleTerm's packaging is verified in CI by building the **real** `.deb`,
`.rpm`, and `.pkg.tar.zst` and asserting against the actual artifacts. It is
easy, on a laptop, to run a quick static check — grep a file, run a Python test
that inspects source — see it pass, and believe the packages are good. They are
not the same signal. A static grep can pass while the real `rpmbuild` fails on
unpackaged files, or a verifier crashes on an undefined variable, or a package
name has drifted. (This bit us: the fix that greened packaging was preceded by a
local suite reporting `12/12 pass` while the real build jobs were red.)

`preflight` closes that gap. It runs the **same gates CI runs**, in the same
way, and tells you honestly which ones actually executed.

## What you get

- **Every CI packaging verifier**, run locally where the host can: the layout
  and Arch-metadata checks always run; the deb/rpm/arch **real-build** verifiers
  run when `dpkg-deb` / `rpmbuild` / `zstd` (+ an x86_64/aarch64 host) are
  present, and are otherwise **skipped with the reason stated**.
- A **verdict you can trust**:
  - `GREEN — full CI parity` only when nothing was skipped.
  - `PARTIAL` when a real-build verifier was skipped — so a laptop pass is never
    mistaken for the full CI signal. Get full parity on a Linux host with the
    packaging tools installed (`apt-get install dpkg-dev rpm zstd`) or rely on
    the CI packaging workflows.
  - `FAILED` (non-zero exit) if any gate that ran failed.
- A **gate-drift self-check**: preflight parses the packaging workflows and
  fails if CI runs a `verify-*.sh` that preflight doesn't — so the local gate
  set cannot silently fall behind what CI enforces.

## The rule

If you touched anything under `packaging/`, `assets/sourceos/`, or the packaging
workflows, run `make preflight` before you push. If it says `PARTIAL`, the
real-build verifiers for the skipped formats only run in CI — watch them there.
