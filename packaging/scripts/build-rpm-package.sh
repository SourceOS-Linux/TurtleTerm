#!/usr/bin/env bash
set -euo pipefail

version="${TURTLE_TERM_VERSION:-0.1.0}"
arch="${TURTLE_TERM_RPM_ARCH:-$(uname -m)}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${TURTLE_TERM_OUT_DIR:-$repo_root/dist}"
rpmbuild_root="$out_dir/rpmbuild"
spec="$rpmbuild_root/SPECS/turtle-term.spec"

command -v rpmbuild >/dev/null 2>&1 || { echo "rpmbuild is required" >&2; exit 1; }

rm -rf "$rpmbuild_root"
mkdir -p "$rpmbuild_root/BUILD" "$rpmbuild_root/BUILDROOT" "$rpmbuild_root/RPMS" "$rpmbuild_root/SOURCES" "$rpmbuild_root/SPECS" "$rpmbuild_root/SRPMS"

cat > "$spec" <<EOF
Name:           turtleterm
Version:        $version
Release:        1%{?dist}
Summary:        TurtleTerm trusted terminal and agent workbench
License:        MIT
URL:            https://github.com/SourceOS-Linux/TurtleTerm
BuildArch:      $arch
Requires:       python3 >= 3.10
Requires:       fontconfig
Requires:       freetype
Requires:       libX11
Requires:       libxcb
Requires:       libxkbcommon
Requires:       openssl-libs
Requires:       zlib

%description
TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench
for trusted command execution, terminal receipts, agent delegation, language intelligence,
session ergonomics, and reproducible operator workflows.

%prep

%build

%install
rm -rf %{buildroot}
TURTLE_TERM_STAGE_PREFIX=%{buildroot}/usr TURTLE_TERM_ETC_DIR=%{buildroot}/etc TURTLE_TERM_RUNTIME_PREFIX=/usr TURTLE_TERM_RUNTIME_ETC_DIR=/etc bash $repo_root/packaging/scripts/stage-linux-package.sh >/dev/null
cp $repo_root/LICENSE.md %{buildroot}/LICENSE.md
if [ -f $repo_root/THIRD_PARTY_NOTICES.md ]; then cp $repo_root/THIRD_PARTY_NOTICES.md %{buildroot}/THIRD_PARTY_NOTICES.md; fi

%files
%license /LICENSE.md
%doc /THIRD_PARTY_NOTICES.md
# Glob the whole staged tree so %files always matches what
# stage-linux-package.sh installs (all agent commands, runtime, data) —
# an explicit list silently desyncs and trips "unpackaged file(s) found".
/usr/bin/*
/etc/turtle-term/turtleterm.lua
/usr/libexec/turtle-term/
/usr/share/applications/ai.sourceos.TurtleTerm.desktop
/usr/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml
/usr/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg
/usr/share/turtle-term/
EOF

rpmbuild --define "_topdir $rpmbuild_root" -bb "$spec" >&2
rpm="$(find "$rpmbuild_root/RPMS" -name 'turtleterm-*.rpm' -print -quit)"
if [ -z "$rpm" ]; then
  echo "no turtle-term RPM built under $rpmbuild_root/RPMS" >&2
  find "$rpmbuild_root" -maxdepth 4 -type f -print >&2
  exit 1
fi
sha256sum "$rpm" > "$rpm.sha256"
python3 "$repo_root/packaging/scripts/write-native-package-manifest.py" \
  --package "$rpm" \
  --kind rpm \
  --version "$version" \
  --arch "$arch" \
  --out "$rpm.manifest.json" >/dev/null

# stdout must carry ONLY the package path — verify-rpm-package.sh captures it
# via command substitution, so any earlier chatter corrupts "$rpm".
echo "$rpm"