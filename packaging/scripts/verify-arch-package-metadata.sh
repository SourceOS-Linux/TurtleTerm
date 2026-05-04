#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pkgbuild="$repo_root/packaging/linux/arch/PKGBUILD"

test -f "$pkgbuild"
bash -n "$pkgbuild"

grep -q '^pkgname=turtle-term$' "$pkgbuild"
grep -q '^pkgver=0.1.0$' "$pkgbuild"
grep -q "arch=('x86_64' 'aarch64')" "$pkgbuild"
grep -q "license=('MIT')" "$pkgbuild"
grep -q 'https://github.com/SourceOS-Linux/TurtleTerm' "$pkgbuild"
grep -q 'TURTLE_TERM_STAGE_PREFIX' "$pkgbuild"
grep -q 'packaging/scripts/stage-linux-package.sh' "$pkgbuild"

if grep -qi 'org.wezfurlong\|SourceOS-Linux/wezterm' "$pkgbuild"; then
  echo 'PKGBUILD contains stale upstream product identity' >&2
  exit 1
fi

echo "verified TurtleTerm Arch package metadata"
