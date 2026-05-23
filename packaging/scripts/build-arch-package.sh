#!/usr/bin/env bash
set -euo pipefail

version="${TURTLE_TERM_VERSION:-0.1.0}"
arch="${TURTLE_TERM_ARCH_ARCH:-$(uname -m)}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${TURTLE_TERM_OUT_DIR:-$repo_root/dist}"
pkgroot="$out_dir/arch-root"
pkg="$out_dir/turtle-term-${version}-1-${arch}.pkg.tar.zst"

case "$arch" in
  x86_64|aarch64) ;;
  *) echo "unsupported Arch architecture: $arch" >&2; exit 2 ;;
esac

command -v tar >/dev/null 2>&1 || { echo "tar is required" >&2; exit 1; }
command -v zstd >/dev/null 2>&1 || { echo "zstd is required" >&2; exit 1; }

rm -rf "$pkgroot" "$pkg" "$pkg.sha256" "$pkg.manifest.json"
mkdir -p "$pkgroot" "$out_dir"

TURTLE_TERM_STAGE_PREFIX="$pkgroot/usr" \
TURTLE_TERM_ETC_DIR="$pkgroot/etc" \
TURTLE_TERM_RUNTIME_PREFIX="/usr" \
TURTLE_TERM_RUNTIME_ETC_DIR="/etc" \
  bash "$repo_root/packaging/scripts/stage-linux-package.sh" >/dev/null

cat > "$pkgroot/.PKGINFO" <<EOF
pkgname = turtle-term
pkgbase = turtle-term
pkgver = $version-1
pkgdesc = TurtleTerm trusted terminal and agent workbench
url = https://github.com/SourceOS-Linux/TurtleTerm
builddate = 0
packager = SourceOS Linux <maintainers@sourceos.local>
size = 0
arch = $arch
license = MIT
depend = fontconfig
depend = freetype2
depend = libx11
depend = libxcb
depend = libxkbcommon
depend = openssl
depend = zlib
EOF

cat > "$pkgroot/.INSTALL" <<'EOF'
post_install() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
  fi
}

post_upgrade() {
  post_install
}

post_remove() {
  post_install
}
EOF

find "$pkgroot" -type d -exec chmod 0755 {} +
find "$pkgroot/usr/bin" -type f -exec chmod 0755 {} +
find "$pkgroot/usr/libexec/turtle-term" -type f -exec chmod 0755 {} +

tar --zstd -C "$pkgroot" -cf "$pkg" .
sha256sum "$pkg" > "$pkg.sha256"
python3 "$repo_root/packaging/scripts/write-native-package-manifest.py" \
  --package "$pkg" \
  --kind arch \
  --version "$version" \
  --arch "$arch" \
  --out "$pkg.manifest.json"

echo "$pkg"
