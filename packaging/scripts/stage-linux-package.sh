#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
prefix="${TURTLE_TERM_STAGE_PREFIX:-$repo_root/dist/linux-prefix}"
etc_dir="${TURTLE_TERM_ETC_DIR:-$prefix/etc}"
runtime_prefix="${TURTLE_TERM_RUNTIME_PREFIX:-$prefix}"
runtime_etc_dir="${TURTLE_TERM_RUNTIME_ETC_DIR:-$etc_dir}"

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
  "$prefix/share/turtle-term/desktop" \
  "$prefix/share/turtle-term/shell"

cp "$repo_root/target/release/wezterm" "$prefix/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm-gui" "$prefix/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm-mux-server" "$prefix/libexec/turtle-term/"

for script in \
  sourceos-term \
  turtle-term \
  turtle-agentd \
  turtle-agentctl \
  turtle-agent-status \
  turtle-tmux \
  turtle-cloudfog \
  turtle-superconscious \
  turtle-agent-machine \
  turtle-language \
  turtle-session \
  turtle-synapseiq \
  synapseiq-lsp \
  turtle-plan-view \
  turtle-selftest \
  turtle-runbook \
  turtle-voice \
  turtle-sync \
  turtle-perf \
  turtle-persona \
  turtle-files \
  turtle-bg \
  turtle-dash \
  turtle-pr \
  turtle-issue \
  turtle-hooks \
  turtle-gitea \
  turtle-ci \
  turtle-review \
  turtle-watch \
  turtle-cost \
  turtle-copilot \
  turtle-gh \
  turtle-env \
  turtle-diagnose \
  turtle-apply \
  turtle-chain \
  turtle-ai-chat; do
  cp "$repo_root/assets/sourceos/bin/$script" "$prefix/bin/"
  chmod 0755 "$prefix/bin/$script"
done

cp "$repo_root/assets/sourceos/bin/turtleterm" "$prefix/libexec/turtle-term/turtleterm"
cp "$repo_root/assets/sourceos/bin/turtleterm-mux-server" "$prefix/libexec/turtle-term/turtleterm-mux-server"
chmod 0755 "$prefix/libexec/turtle-term/turtleterm" "$prefix/libexec/turtle-term/turtleterm-mux-server"

cat > "$prefix/bin/turtleterm" <<EOF
#!/usr/bin/env sh
export TURTLE_TERM_RUNTIME_DIR="$runtime_prefix/libexec/turtle-term"
export TURTLETERM_CONFIG="$runtime_etc_dir/turtle-term/turtleterm.lua"
exec "$runtime_prefix/libexec/turtle-term/turtleterm" "\$@"
EOF
chmod 0755 "$prefix/bin/turtleterm"

cat > "$prefix/bin/turtleterm-mux-server" <<EOF
#!/usr/bin/env sh
export TURTLE_TERM_RUNTIME_DIR="$runtime_prefix/libexec/turtle-term"
exec "$runtime_prefix/libexec/turtle-term/turtleterm-mux-server" "\$@"
EOF
chmod 0755 "$prefix/bin/turtleterm-mux-server"

# Shell integration
for f in \
  turtle-shell-init.zsh \
  turtle-shell-init.bash \
  turtle-shell-init.fish \
  turtle-shell-init.ps1 \
  turtle-agentctl-completions.zsh \
  turtle-agentctl-completions.bash \
  turtle-agentctl-completions.fish \
  turtle-agentctl-completions.ps1 \
  turtle-gh-completions.zsh \
  turtle-gh-completions.bash \
  turtle-copilot-completions.zsh \
  turtle-copilot-completions.bash; do
  if [ -f "$repo_root/assets/sourceos/shell/$f" ]; then
    cp "$repo_root/assets/sourceos/shell/$f" "$prefix/share/turtle-term/shell/"
  fi
done

# MCP server
if [ -f "$repo_root/assets/sourceos/mcp/turtle-mcp-server" ]; then
  mkdir -p "$prefix/share/turtle-term/mcp"
  cp "$repo_root/assets/sourceos/mcp/turtle-mcp-server" "$prefix/share/turtle-term/mcp/"
  chmod 0755 "$prefix/share/turtle-term/mcp/turtle-mcp-server"
  ln -sf "$runtime_prefix/share/turtle-term/mcp/turtle-mcp-server" "$prefix/bin/turtle-mcp-server"
fi

cp "$repo_root/assets/sourceos/turtleterm.lua" "$etc_dir/turtle-term/turtleterm.lua"
cp "$repo_root/assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop" "$prefix/share/applications/"
cp "$repo_root/assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml" "$prefix/share/metainfo/"
cp "$repo_root/assets/sourceos/brand/ai.sourceos.TurtleTerm.svg" "$prefix/share/icons/hicolor/scalable/apps/"
cp -R "$repo_root/docs/sourceos/." "$prefix/share/turtle-term/sourceos/"
cp -R "$repo_root/assets/sourceos/skills/." "$prefix/share/turtle-term/skills/"
cp -R "$repo_root/assets/sourceos/brand/." "$prefix/share/turtle-term/brand/"
cp -R "$repo_root/assets/sourceos/desktop/." "$prefix/share/turtle-term/desktop/"

printf 'Staged TurtleTerm Linux package layout at %s\n' "$prefix"
