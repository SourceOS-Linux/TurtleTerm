#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$repo_root/target/release"
for binary in wezterm wezterm-gui wezterm-mux-server; do
  cat > "$repo_root/target/release/$binary" <<'EOF'
#!/usr/bin/env sh
echo turtleterm-stub
EOF
  chmod 0755 "$repo_root/target/release/$binary"
done

TURTLE_TERM_OUT_DIR="$tmp" TURTLE_TERM_VERSION="0.1.0" TURTLE_TERM_RPM_ARCH="$(uname -m)" bash "$repo_root/packaging/scripts/build-rpm-package.sh" >/dev/null
rpm="$(find "$tmp" -maxdepth 1 -type f -name '*.rpm' | sort | head -n 1)"
extract="$tmp/extract"

test -n "$rpm"
test -f "$rpm"
test -f "$rpm.sha256"
test -f "$rpm.manifest.json"
sha256sum -c "$rpm.sha256" >/dev/null
python3 - <<PY
import json
from pathlib import Path
manifest = json.loads(Path('$rpm.manifest.json').read_text())
assert manifest['schema'] == 'sourceos.turtle-term.native-package.manifest.v0'
assert manifest['product'] == 'TurtleTerm'
assert manifest['kind'] == 'rpm'
assert manifest['version'] == '0.1.0'
assert manifest['package'].endswith('.rpm')
assert manifest['profile'] == '/etc/turtle-term/turtleterm.lua'
PY

rpm -qp --queryformat '%{NAME}\n' "$rpm" | grep -qx 'turtle-term'
rpm -qp --queryformat '%{VERSION}\n' "$rpm" | grep -qx '0.1.0'

for path in \
  '^/usr/bin/turtleterm$' \
  '^/usr/bin/turtle-agentctl$' \
  '^/etc/turtle-term/turtleterm.lua$' \
  '^/usr/share/applications/ai.sourceos.TurtleTerm.desktop$' \
  '^/usr/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml$' \
  '^/usr/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg$' \
  '^/usr/libexec/turtle-term/wezterm-gui$'; do
  rpm -qpl "$rpm" | grep -q "$path"
done

if rpm -qpl "$rpm" | grep -q '^/usr/bin/wezterm-gui$'; then
  echo 'private runtime leaked onto product PATH: wezterm-gui' >&2
  exit 1
fi

mkdir -p "$extract"
(cd "$extract" && rpm2cpio "$rpm" | cpio -idmu >/dev/null 2>&1)
grep -q 'TURTLE_TERM_RUNTIME_DIR="/usr/libexec/turtle-term"' "$extract/usr/bin/turtleterm"
grep -q 'TURTLETERM_CONFIG="/etc/turtle-term/turtleterm.lua"' "$extract/usr/bin/turtleterm"
grep -q 'TURTLE_TERM_RUNTIME_DIR="/usr/libexec/turtle-term"' "$extract/usr/bin/turtleterm-mux-server"
if grep -R "$tmp\|BUILDROOT\|rpm-root\|arch-root\|deb-root" "$extract/usr/bin/turtleterm" "$extract/usr/bin/turtleterm-mux-server"; then
  echo 'buildroot path leaked into RPM launch wrappers' >&2
  exit 1
fi

echo "verified $rpm"
