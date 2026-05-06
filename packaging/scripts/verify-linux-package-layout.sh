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

prefix="$tmp/prefix"
TURTLE_TERM_STAGE_PREFIX="$prefix" bash "$repo_root/packaging/scripts/stage-linux-package.sh" >/dev/null

required_paths=(
  "$prefix/bin/turtleterm"
  "$prefix/bin/turtleterm-mux-server"
  "$prefix/bin/turtle-term"
  "$prefix/bin/turtle-agentd"
  "$prefix/bin/turtle-agentctl"
  "$prefix/bin/turtle-tmux"
  "$prefix/bin/turtle-cloudfog"
  "$prefix/bin/turtle-superconscious"
  "$prefix/bin/turtle-agent-machine"
  "$prefix/bin/sourceos-term"
  "$prefix/etc/turtle-term/turtleterm.lua"
  "$prefix/libexec/turtle-term/wezterm"
  "$prefix/libexec/turtle-term/wezterm-gui"
  "$prefix/libexec/turtle-term/wezterm-mux-server"
  "$prefix/share/applications/ai.sourceos.TurtleTerm.desktop"
  "$prefix/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml"
  "$prefix/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg"
  "$prefix/share/turtle-term/skills"
  "$prefix/share/turtle-term/brand"
  "$prefix/share/turtle-term/desktop"
  "$prefix/share/turtle-term/sourceos"
)

for path in "${required_paths[@]}"; do
  if [ ! -e "$path" ]; then
    echo "missing expected TurtleTerm package path: $path" >&2
    exit 1
  fi
done

for private_binary in wezterm wezterm-gui wezterm-mux-server; do
  if [ -e "$prefix/bin/$private_binary" ]; then
    echo "private runtime binary leaked onto product PATH: $private_binary" >&2
    exit 1
  fi
done

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$prefix/share/applications/ai.sourceos.TurtleTerm.desktop"
fi

if command -v appstreamcli >/dev/null 2>&1; then
  appstreamcli validate --no-net "$prefix/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml"
fi

"$prefix/bin/turtle-agentctl" --stdio ping >/dev/null
"$prefix/bin/turtle-agentctl" --stdio surfaces >/dev/null
"$prefix/bin/turtle-cloudfog" surfaces >/dev/null
"$prefix/bin/turtle-superconscious" observe package-layout >/dev/null
"$prefix/bin/turtle-agent-machine" surfaces >/dev/null

echo "verified TurtleTerm Linux package layout at $prefix"
