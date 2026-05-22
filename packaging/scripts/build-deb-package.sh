#!/usr/bin/env bash
set -euo pipefail

version="${TURTLE_TERM_VERSION:-0.1.0}"
arch="${TURTLE_TERM_DEB_ARCH:-amd64}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${TURTLE_TERM_OUT_DIR:-$repo_root/dist}"
package_root="$out_dir/deb-root"
prefix="$package_root/usr"
etc_dir="$package_root/etc"
debian_dir="$package_root/DEBIAN"
deb_build="$out_dir/deb-build"
deb="$out_dir/turtle-term_${version}_${arch}.deb"

case "$arch" in
  amd64|arm64) ;;
  *) echo "unsupported Debian architecture: $arch" >&2; exit 2 ;;
esac

command -v ar >/dev/null 2>&1 || { echo "ar is required" >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "tar is required" >&2; exit 1; }
command -v gzip >/dev/null 2>&1 || { echo "gzip is required" >&2; exit 1; }

rm -rf "$package_root" "$deb_build" "$deb" "$deb.sha256" "$deb.manifest.json"
mkdir -p "$debian_dir" "$out_dir" "$deb_build"

TURTLE_TERM_STAGE_PREFIX="$prefix" \
TURTLE_TERM_ETC_DIR="$etc_dir" \
TURTLE_TERM_RUNTIME_PREFIX="/usr" \
TURTLE_TERM_RUNTIME_ETC_DIR="/etc" \
  "$repo_root/packaging/scripts/stage-linux-package.sh" >/dev/null

cat > "$debian_dir/control" <<EOF
Package: turtle-term
Version: $version
Section: devel
Priority: optional
Architecture: $arch
Maintainer: SourceOS Linux <maintainers@sourceos.local>
Depends: libc6, libfontconfig1, libfreetype6, libssl3, libx11-6, libxcb1, libxkbcommon0, zlib1g
Homepage: https://github.com/SourceOS-Linux/TurtleTerm
Description: TurtleTerm trusted terminal and agent workbench
 TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench
 for trusted command execution, terminal receipts, agent delegation, and
 reproducible operator workflows.
EOF

cat > "$debian_dir/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
exit 0
EOF
chmod 0755 "$debian_dir/postinst"

cat > "$debian_dir/prerm" <<'EOF'
#!/bin/sh
set -e
exit 0
EOF
chmod 0755 "$debian_dir/prerm"

find "$package_root" -type d -exec chmod 0755 {} +
find "$package_root/usr/bin" -type f -exec chmod 0755 {} +
find "$package_root/usr/libexec/turtle-term" -type f -exec chmod 0755 {} +

printf '2.0\n' > "$deb_build/debian-binary"
(
  cd "$debian_dir"
  tar --owner=0 --group=0 --numeric-owner -czf "$deb_build/control.tar.gz" .
)
(
  cd "$package_root"
  tar --owner=0 --group=0 --numeric-owner --exclude='./DEBIAN' -czf "$deb_build/data.tar.gz" .
)
(
  cd "$deb_build"
  ar rcs "$deb" debian-binary control.tar.gz data.tar.gz
)

sha256sum "$deb" > "$deb.sha256"
python3 "$repo_root/packaging/scripts/write-native-package-manifest.py" \
  --package "$deb" \
  --kind deb \
  --version "$version" \
  --arch "$arch" \
  --out "$deb.manifest.json"

echo "$deb"
