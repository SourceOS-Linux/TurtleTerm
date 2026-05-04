#!/usr/bin/env bash
set -euo pipefail

version="${TURTLE_TERM_VERSION:-0.1.0}"
arch="${TURTLE_TERM_RPM_ARCH:-$(uname -m)}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${TURTLE_TERM_OUT_DIR:-$repo_root/dist}"
rpmbuild_root="$out_dir/rpmbuild"
buildroot="$rpmbuild_root/BUILDROOT/turtle-term-$version-1.$arch"
spec="$rpmbuild_root/SPECS/turtle-term.spec"

command -v rpmbuild >/dev/null 2>&1 || { echo "rpmbuild is required" >&2; exit 1; }

rm -rf "$rpmbuild_root"
mkdir -p "$rpmbuild_root/BUILD" "$rpmbuild_root/BUILDROOT" "$rpmbuild_root/RPMS" "$rpmbuild_root/SOURCES" "$rpmbuild_root/SPECS" "$rpmbuild_root/SRPMS"
mkdir -p "$buildroot"

TURTLE_TERM_STAGE_PREFIX="$buildroot/usr" TURTLE_TERM_ETC_DIR="$buildroot/etc" \
  "$repo_root/packaging/scripts/stage-linux-package.sh" >/dev/null

cat > "$spec" <<EOF
Name:           turtle-term
Version:        $version
Release:        1%{?dist}
Summary:        TurtleTerm trusted terminal and agent workbench
License:        MIT
URL:            https://github.com/SourceOS-Linux/TurtleTerm
BuildArch:      $arch
Requires:       fontconfig
Requires:       freetype
Requires:       libX11
Requires:       libxcb
Requires:       libxkbcommon
Requires:       openssl-libs
Requires:       zlib

%description
TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench
for trusted command execution, terminal receipts, agent delegation, and
reproducible operator workflows.

%prep

%build

%install
# Files are staged before rpmbuild by build-rpm-package.sh.

%files
%license /LICENSE.md
/usr/bin/turtleterm
/usr/bin/turtleterm-mux-server
/usr/bin/turtle-term
/usr/bin/turtle-agentd
/usr/bin/turtle-agentctl
/usr/bin/turtle-tmux
/usr/bin/sourceos-term
/etc/turtle-term/turtleterm.lua
/usr/libexec/turtle-term/
/usr/share/applications/ai.sourceos.TurtleTerm.desktop
/usr/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml
/usr/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg
/usr/share/turtle-term/
EOF

cp "$repo_root/LICENSE.md" "$buildroot/LICENSE.md"
cp "$repo_root/THIRD_PARTY_NOTICES.md" "$buildroot/THIRD_PARTY_NOTICES.md" 2>/dev/null || true

rpmbuild --define "_topdir $rpmbuild_root" --buildroot "$buildroot" -bb "$spec" >/dev/null
find "$rpmbuild_root/RPMS" -name 'turtle-term-*.rpm' -print -quit
