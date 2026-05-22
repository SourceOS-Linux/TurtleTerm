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
extract="$tmp/extract"
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
for command in ['turtle-cloudfog', 'turtle-superconscious', 'turtle-agent-machine', 'turtle-language', 'turtle-session']:
    assert command in manifest['public_commands'], command
PY

dpkg-deb --field "$deb" Package | grep -qx 'turtle-term'
dpkg-deb --field "$deb" Version | grep -qx '0.1.0'
dpkg-deb --field "$deb" Architecture | grep -qx 'amd64'

for command in turtleterm turtle-agentctl turtle-cloudfog turtle-superconscious turtle-agent-machine turtle-language turtle-session; do
  dpkg-deb --contents "$deb" | grep -q "/usr/bin/$command$"
done

dpkg-deb --contents "$deb" | grep -q '/etc/turtle-term/turtleterm.lua$'
dpkg-deb --contents "$deb" | grep -q '/usr/share/applications/ai.sourceos.TurtleTerm.desktop$'
dpkg-deb --contents "$deb" | grep -q '/usr/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml$'
dpkg-deb --contents "$deb" | grep -q '/usr/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg$'
dpkg-deb --contents "$deb" | grep -q '/usr/libexec/turtle-term/wezterm-gui$'

if dpkg-deb --contents "$deb" | grep -q '/usr/bin/wezterm-gui$'; then
  echo 'private runtime leaked onto product PATH in deb' >&2
  exit 1
fi

mkdir -p "$extract"
dpkg-deb -x "$deb" "$extract"
grep -q 'TURTLE_TERM_RUNTIME_DIR="/usr/libexec/turtle-term"' "$extract/usr/bin/turtleterm"
grep -q 'TURTLETERM_CONFIG="/etc/turtle-term/turtleterm.lua"' "$extract/usr/bin/turtleterm"
grep -q 'exec "/usr/libexec/turtle-term/turtleterm"' "$extract/usr/bin/turtleterm"
grep -q 'TURTLE_TERM_RUNTIME_DIR="/usr/libexec/turtle-term"' "$extract/usr/bin/turtleterm-mux-server"
grep -q 'exec "/usr/libexec/turtle-term/turtleterm-mux-server"' "$extract/usr/bin/turtleterm-mux-server"
if grep -R "$tmp\|deb-root\|BUILDROOT\|arch-root" "$extract/usr/bin/turtleterm" "$extract/usr/bin/turtleterm-mux-server"; then
  echo 'buildroot path leaked into Debian launch wrappers' >&2
  exit 1
fi

probe="$tmp/probe.py"
printf 'def hello():\n    return "world"\n' > "$probe"
PATH="$extract/usr/bin:$PATH" "$extract/usr/bin/turtle-agentctl" --stdio surfaces >/dev/null
PATH="$extract/usr/bin:$PATH" "$extract/usr/bin/turtle-cloudfog" surfaces >/dev/null
PATH="$extract/usr/bin:$PATH" "$extract/usr/bin/turtle-superconscious" observe deb-package >/dev/null
PATH="$extract/usr/bin:$PATH" "$extract/usr/bin/turtle-agent-machine" surfaces >/dev/null
PATH="$extract/usr/bin:$PATH" "$extract/usr/bin/turtle-language" diagnostics "$probe" >/dev/null
PATH="$extract/usr/bin:$PATH" "$extract/usr/bin/turtle-language" symbols "$probe" >/dev/null
PATH="$extract/usr/bin:$PATH" TURTLE_SESSION_STATE="$tmp/session-state" "$extract/usr/bin/turtle-session" profiles >/dev/null
PATH="$extract/usr/bin:$PATH" TURTLE_SESSION_STATE="$tmp/session-state" "$extract/usr/bin/turtle-session" replay-plan >/dev/null

echo "verified $deb"
