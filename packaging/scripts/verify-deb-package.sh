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

TURTLE_TERM_OUT_DIR="$tmp" TURTLE_TERM_VERSION="0.1.0" TURTLE_TERM_DEB_ARCH="amd64" \
  "$repo_root/packaging/scripts/build-deb-package.sh" >/dev/null

deb="$tmp/turtle-term_0.1.0_amd64.deb"
test -f "$deb"
test -f "$deb.sha256"
test -f "$deb.manifest.json"
sha256sum -c "$deb.sha256" >/dev/null
python3 - <<PY
import json
from pathlib import Path
manifest = json.loads(Path('$deb.manifest.json').read_text())
assert manifest['schema'] == 'sourceos.turtle-term.native-package.manifest.v0'
assert manifest['product'] == 'TurtleTerm'
assert manifest['kind'] == 'deb'
assert manifest['version'] == '0.1.0'
assert manifest['arch'] == 'amd64'
assert manifest['package'] == 'turtle-term_0.1.0_amd64.deb'
assert manifest['profile'] == '/etc/turtle-term/turtleterm.lua'
PY

dpkg-deb --field "$deb" Package | grep -qx 'turtle-term'
dpkg-deb --field "$deb" Version | grep -qx '0.1.0'
dpkg-deb --field "$deb" Architecture | grep -qx 'amd64'

dpkg-deb --contents "$deb" | grep -q '/usr/bin/turtleterm$'
dpkg-deb --contents "$deb" | grep -q '/usr/bin/turtle-agentctl$'
dpkg-deb --contents "$deb" | grep -q '/etc/turtle-term/turtleterm.lua$'
dpkg-deb --contents "$deb" | grep -q '/usr/share/applications/ai.sourceos.TurtleTerm.desktop$'
dpkg-deb --contents "$deb" | grep -q '/usr/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml$'
dpkg-deb --contents "$deb" | grep -q '/usr/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg$'
dpkg-deb --contents "$deb" | grep -q '/usr/libexec/turtle-term/wezterm-gui$'

if dpkg-deb --contents "$deb" | grep -q '/usr/bin/wezterm-gui$'; then
  echo 'private runtime leaked onto product PATH in deb' >&2
  exit 1
fi

echo "verified $deb"
