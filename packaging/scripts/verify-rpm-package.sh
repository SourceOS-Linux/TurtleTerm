#!/usr/bin/env bash
set -eu

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

require_rpm_path() {
  local pattern="$1"
  if ! rpm -qpl "$rpm" | grep -q "$pattern"; then
    echo "missing expected RPM path matching: $pattern" >&2
    echo "RPM contents:" >&2
    rpm -qpl "$rpm" >&2
    exit 1
  fi
}

require_file_text() {
  local path="$1"
  local pattern="$2"
  if ! grep -q "$pattern" "$path"; then
    echo "missing expected text in $path: $pattern" >&2
    echo "--- $path ---" >&2
    cat "$path" >&2
    echo "--- end $path ---" >&2
    exit 1
  fi
}

mkdir -p "$repo_root/target/release"
for binary in wezterm wezterm-gui wezterm-mux-server; do
  cat > "$repo_root/target/release/$binary" <<'EOF'
#!/usr/bin/env sh
echo turtleterm-stub
EOF
  chmod 0755 "$repo_root/target/release/$binary"
done

rpm="$(TURTLE_TERM_OUT_DIR="$tmp" TURTLE_TERM_VERSION="0.1.0" TURTLE_TERM_RPM_ARCH="$(uname -m)" \
  bash "$repo_root/packaging/scripts/build-rpm-package.sh")"
extract="$tmp/extract"

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

require_rpm_path '^/usr/bin/turtleterm$'
require_rpm_path '^/usr/bin/turtle-agentctl$'
require_rpm_path '^/etc/turtle-term/turtleterm.lua$'
require_rpm_path '^/usr/share/applications/ai.sourceos.TurtleTerm.desktop$'
require_rpm_path '^/usr/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml$'
require_rpm_path '^/usr/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg$'
require_rpm_path '^/usr/libexec/turtle-term/wezterm-gui$'

if rpm -qpl "$rpm" | grep -q '^/usr/bin/wezterm-gui$'; then
  echo 'private runtime leaked onto product PATH in rpm' >&2
  exit 1
fi

mkdir -p "$extract"
(cd "$extract" && rpm2cpio "$rpm" | cpio -idmu >/dev/null 2>&1)
require_file_text "$extract/usr/bin/turtleterm" 'TURTLE_TERM_RUNTIME_DIR="/usr/libexec/turtle-term"'
require_file_text "$extract/usr/bin/turtleterm" 'TURTLETERM_CONFIG="/etc/turtle-term/turtleterm.lua"'
require_file_text "$extract/usr/bin/turtleterm" 'exec "/usr/libexec/turtle-term/turtleterm"'
require_file_text "$extract/usr/bin/turtleterm-mux-server" 'TURTLE_TERM_RUNTIME_DIR="/usr/libexec/turtle-term"'
require_file_text "$extract/usr/bin/turtleterm-mux-server" 'exec "/usr/libexec/turtle-term/turtleterm-mux-server"'
if grep -R "$tmp\|BUILDROOT\|rpm-root\|arch-root\|deb-root" "$extract/usr/bin/turtleterm" "$extract/usr/bin/turtleterm-mux-server"; then
  echo 'buildroot path leaked into RPM launch wrappers' >&2
  exit 1
fi

echo "verified $rpm"
