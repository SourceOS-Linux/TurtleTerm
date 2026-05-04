#!/usr/bin/env bash
set -euo pipefail

version="${TURTLE_TERM_VERSION:-0.1.0}"
arch="${TURTLE_TERM_DEB_ARCH:-amd64}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${TURTLE_TERM_OUT_DIR:-$repo_root/dist}"
package_root="$out_dir/deb-root"
prefix="$package_root/usr"
debian_dir="$package_root/DEBIAN"
deb="$out_dir/turtle-term_${version}_${arch}.deb"

case "$arch" in
  amd64|arm64) ;;
  *) echo "unsupported Debian architecture: $arch" >&2; exit 2 ;;
esac

command -v dpkg-deb >/dev/null 2>&1 || { echo "dpkg-deb is required" >&2; exit 1; }

rm -rf "$package_root" "$deb"
mkdir -p "$debian_dir" "$out_dir"

TURTLE_TERM_STAGE_PREFIX="$prefix" "$repo_root/packaging/scripts/stage-linux-package.sh" >/dev/null

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

dpkg-deb --build --root-owner-group "$package_root" "$deb" >/dev/null

echo "$deb"
