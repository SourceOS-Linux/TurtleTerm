#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
prefix="${TURTLE_TERM_STAGE_PREFIX:-$repo_root/dist/linux-prefix}"
etc_dir="${TURTLE_TERM_ETC_DIR:-$prefix/etc}"

mkdir -p \
  "$prefix/bin" \
  "$etc_dir/turtle-term" \
  "$prefix/libexec/turtle-term" \
  "$prefix/share/applications" \
  "$prefix/share/metainfo" \
  "$prefix/share/icons/hicolor/scalable/apps" \
  "$prefix/share/turtle-term/sourceos" \
  "$prefix/share/turtle-term/skills" \
  "$prefix/share/turtle-term/brand" \
  "$prefix/share/turtle-term/desktop"

cp "$repo_root/target/release/wezterm" "$prefix/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm-gui" "$prefix/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm-mux-server" "$prefix/libexec/turtle-term/"

for script in sourceos-term turtle-term turtle-agentd turtle-agentctl turtle-tmux; do
  cp "$repo_root/assets/sourceos/bin/$script" "$prefix/bin/"
  chmod 0755 "$prefix/bin/$script"
done

cp "$repo_root/assets/sourceos/bin/turtleterm" "$prefix/libexec/turtle-term/turtleterm"
cp "$repo_root/assets/sourceos/bin/turtleterm-mux-server" "$prefix/libexec/turtle-term/turtleterm-mux-server"
chmod 0755 "$prefix/libexec/turtle-term/turtleterm" "$prefix/libexec/turtle-term/turtleterm-mux-server"

cat > "$prefix/bin/turtleterm" <<EOF
#!/usr/bin/env sh
export TURTLE_TERM_RUNTIME_DIR="$prefix/libexec/turtle-term"
export TURTLETERM_CONFIG="$etc_dir/turtle-term/turtleterm.lua"
exec "$prefix/libexec/turtle-term/turtleterm" "\$@"
EOF
chmod 0755 "$prefix/bin/turtleterm"

cat > "$prefix/bin/turtleterm-mux-server" <<EOF
#!/usr/bin/env sh
export TURTLE_TERM_RUNTIME_DIR="$prefix/libexec/turtle-term"
exec "$prefix/libexec/turtle-term/turtleterm-mux-server" "\$@"
EOF
chmod 0755 "$prefix/bin/turtleterm-mux-server"

cp "$repo_root/assets/sourceos/turtleterm.lua" "$etc_dir/turtle-term/turtleterm.lua"
cp "$repo_root/assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop" "$prefix/share/applications/"
cp "$repo_root/assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml" "$prefix/share/metainfo/"
cp "$repo_root/assets/sourceos/brand/ai.sourceos.TurtleTerm.svg" "$prefix/share/icons/hicolor/scalable/apps/"
cp -R "$repo_root/docs/sourceos/." "$prefix/share/turtle-term/sourceos/"
cp -R "$repo_root/assets/sourceos/skills/." "$prefix/share/turtle-term/skills/"
cp -R "$repo_root/assets/sourceos/brand/." "$prefix/share/turtle-term/brand/"
cp -R "$repo_root/assets/sourceos/desktop/." "$prefix/share/turtle-term/desktop/"

printf 'Staged TurtleTerm Linux package layout at %s\n' "$prefix"
