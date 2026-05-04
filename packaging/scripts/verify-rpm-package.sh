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

rpm="$(TURTLE_TERM_OUT_DIR="$tmp" TURTLE_TERM_VERSION="0.1.0" TURTLE_TERM_RPM_ARCH="$(uname -m)" \
  "$repo_root/packaging/scripts/build-rpm-package.sh")"

test -f "$rpm"

rpm -qp --queryformat '%{NAME}\n' "$rpm" | grep -qx 'turtle-term'
rpm -qp --queryformat '%{VERSION}\n' "$rpm" | grep -qx '0.1.0'

rpm -qpl "$rpm" | grep -q '^/usr/bin/turtleterm$'
rpm -qpl "$rpm" | grep -q '^/usr/bin/turtle-agentctl$'
rpm -qpl "$rpm" | grep -q '^/etc/turtle-term/turtleterm.lua$'
rpm -qpl "$rpm" | grep -q '^/usr/share/applications/ai.sourceos.TurtleTerm.desktop$'
rpm -qpl "$rpm" | grep -q '^/usr/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml$'
rpm -qpl "$rpm" | grep -q '^/usr/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg$'
rpm -qpl "$rpm" | grep -q '^/usr/libexec/turtle-term/wezterm-gui$'

if rpm -qpl "$rpm" | grep -q '^/usr/bin/wezterm-gui$'; then
  echo 'private runtime leaked onto product PATH in rpm' >&2
  exit 1
fi

echo "verified $rpm"
