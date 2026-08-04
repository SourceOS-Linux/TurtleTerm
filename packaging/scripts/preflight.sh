#!/usr/bin/env bash
#
# preflight.sh — run the SAME real gates CI runs, locally, and say honestly
# which ran and which were skipped. The point is that a local "green" means the
# same thing as a CI "green": it builds and verifies the actual packages, not a
# static grep of files that can lie (see the packaging retrospective, RC-2).
#
# Exit non-zero if any gate that RAN failed, OR if the local gate set has
# drifted from what CI enforces (a CI verifier this script doesn't know about).
# Skipped gates (missing dpkg-deb/rpmbuild/zstd, or a non-Linux-package host)
# do NOT fail the run, but they DO downgrade the verdict to PARTIAL so nobody
# mistakes a laptop pass for full CI parity.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

bold=$'\033[1m'; red=$'\033[31m'; grn=$'\033[32m'; ylw=$'\033[33m'; dim=$'\033[2m'; rst=$'\033[0m'
[ -t 1 ] || { bold=; red=; grn=; ylw=; dim=; rst=; }

pass=0; fail=0; skip=0
declare -a failed_gates=()
declare -a skipped_gates=()

run_gate() { # name, command...
  local name="$1"; shift
  local log="$log_dir/$(echo "$name" | tr -c 'A-Za-z0-9' '_').log"
  if "$@" >"$log" 2>&1; then
    printf '  %s✓%s %s\n' "$grn" "$rst" "$name"
    pass=$((pass+1))
  else
    printf '  %s✗ %s%s\n' "$red" "$name" "$rst"
    sed 's/^/      /' "$log" | tail -12
    fail=$((fail+1)); failed_gates+=("$name")
  fi
}

skip_gate() { # name, reason
  printf '  %s∅ %s%s %s(skipped: %s)%s\n' "$ylw" "$1" "$rst" "$dim" "$2" "$rst"
  skip=$((skip+1)); skipped_gates+=("$1 — $2")
}

have() { command -v "$1" >/dev/null 2>&1; }
host_arch="$(uname -m)"
arch_buildable=false
{ have zstd && { [ "$host_arch" = x86_64 ] || [ "$host_arch" = aarch64 ]; }; } && arch_buildable=true

echo "${bold}TurtleTerm preflight — the real CI gates, locally${rst}"

# ── Gate set drift check: CI is the source of truth ─────────────────────────
# Every verify-*.sh a packaging workflow runs must be known here; if CI grows a
# gate this script hasn't adopted, fail loudly instead of giving false parity.
echo "${bold}Gate parity (local set vs CI)${rst}"
known_verifiers="verify-arch-package-metadata.sh verify-arch-package.sh verify-deb-package.sh verify-rpm-package.sh verify-linux-package-layout.sh"
ci_verifiers="$(grep -rhoE 'packaging/scripts/verify-[a-z0-9-]+\.sh' .github/workflows/*.yml 2>/dev/null | xargs -n1 basename | sort -u)"
drift=0
for v in $ci_verifiers; do
  case " $known_verifiers " in
    *" $v "*) ;;
    *) printf '  %s✗ CI runs %s but preflight does not — gate drift%s\n' "$red" "$v" "$rst"; drift=1 ;;
  esac
done
[ "$drift" -eq 0 ] && printf '  %s✓%s preflight covers every CI packaging verifier\n' "$grn" "$rst"

# ── Python tests: EXACTLY the set CI runs (derived from the workflows) ───────
# Deriving from the workflows keeps parity honest — preflight can't run more or
# fewer tests than CI, so a pytest-only helper that isn't a CI gate never trips
# a false failure, and a test CI adds is picked up automatically.
echo "${bold}Python suite (exactly the tests CI runs)${rst}"
ci_tests="$(grep -rhoE 'assets/sourceos/tests/test_[a-z0-9_]+\.py' .github/workflows/*.yml 2>/dev/null | sort -u)"
py_fail=0; py_ran=0
for t in $ci_tests; do
  [ -f "$t" ] || continue
  py_ran=$((py_ran+1))
  if ! python3 "$t" >"$log_dir/py.log" 2>&1; then
    printf '  %s✗ %s%s\n' "$red" "$(basename "$t")" "$rst"; sed 's/^/      /' "$log_dir/py.log" | tail -8
    py_fail=$((py_fail+1))
  fi
done
if [ "$py_fail" -eq 0 ]; then printf '  %s✓%s %s CI-gated python tests pass\n' "$grn" "$rst" "$py_ran"; pass=$((pass+1))
else fail=$((fail+1)); failed_gates+=("python-suite ($py_fail failing)"); fi

# ── Shell verifiers (real artifact builds) ──────────────────────────────────
echo "${bold}Package verifiers${rst}"
run_gate "verify-linux-package-layout.sh"   bash packaging/scripts/verify-linux-package-layout.sh
run_gate "verify-arch-package-metadata.sh"  bash packaging/scripts/verify-arch-package-metadata.sh

if have dpkg-deb; then run_gate "verify-deb-package.sh (builds real .deb)" bash packaging/scripts/verify-deb-package.sh
else skip_gate "verify-deb-package.sh" "dpkg-deb not installed"; fi

if have rpmbuild; then run_gate "verify-rpm-package.sh (builds real .rpm)" bash packaging/scripts/verify-rpm-package.sh
else skip_gate "verify-rpm-package.sh" "rpmbuild not installed"; fi

if $arch_buildable; then run_gate "verify-arch-package.sh (builds real .pkg.tar.zst)" bash packaging/scripts/verify-arch-package.sh
else skip_gate "verify-arch-package.sh" "needs zstd + x86_64/aarch64 host (have: $host_arch)"; fi

# ── Verdict ─────────────────────────────────────────────────────────────────
echo
if [ "$fail" -ne 0 ] || [ "$drift" -ne 0 ]; then
  echo "${bold}${red}PREFLIGHT FAILED${rst} — ${fail} gate(s) failed$( [ "$drift" -ne 0 ] && echo ", gate drift detected")"
  for g in "${failed_gates[@]:-}"; do [ -n "$g" ] && echo "  ${red}·${rst} $g"; done
  exit 1
fi
if [ "$skip" -ne 0 ]; then
  echo "${bold}${ylw}PREFLIGHT PARTIAL${rst} — ${pass} ran, ${skip} skipped. ${dim}Not full CI parity; the real deb/rpm/arch builds run in CI (or a Linux host with dpkg-deb/rpmbuild/zstd).${rst}"
  for g in "${skipped_gates[@]:-}"; do [ -n "$g" ] && echo "  ${ylw}·${rst} $g"; done
  exit 0
fi
echo "${bold}${grn}PREFLIGHT GREEN — full CI parity${rst} (${pass} gates, nothing skipped)"
exit 0
