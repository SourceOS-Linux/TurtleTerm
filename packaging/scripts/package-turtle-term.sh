#!/usr/bin/env bash
set -euo pipefail

version="${1:-dev}"
target="${2:-$(uname -s)-$(uname -m)}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="$repo_root/dist"
stage="$out_dir/turtle-term-$version-$target"
archive="$out_dir/turtle-term-$version-$target.tar.gz"
manifest="$archive.manifest.json"

rm -rf "$stage"
mkdir -p \
  "$stage/bin" \
  "$stage/etc/turtle-term" \
  "$stage/share/applications" \
  "$stage/share/icons/hicolor/scalable/apps" \
  "$stage/share/metainfo" \
  "$stage/share/turtle-term/sourceos" \
  "$stage/share/turtle-term/skills" \
  "$stage/share/turtle-term/brand" \
  "$stage/share/turtle-term/desktop" \
  "$stage/libexec/turtle-term"

cp "$repo_root/target/release/wezterm" "$stage/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm-gui" "$stage/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm-mux-server" "$stage/libexec/turtle-term/"

for script in sourceos-term turtle-term turtle-agentd turtle-agentctl turtle-tmux turtleterm turtleterm-mux-server; do
  cp "$repo_root/assets/sourceos/bin/$script" "$stage/bin/"
  chmod 0755 "$stage/bin/$script"
done

cp "$repo_root/assets/sourceos/turtleterm.lua" "$stage/etc/turtle-term/turtleterm.lua"
cp "$repo_root/assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop" "$stage/share/applications/"
cp "$repo_root/assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml" "$stage/share/metainfo/"
cp "$repo_root/assets/sourceos/brand/ai.sourceos.TurtleTerm.svg" "$stage/share/icons/hicolor/scalable/apps/"
cp -R "$repo_root/docs/sourceos/." "$stage/share/turtle-term/sourceos/"
cp -R "$repo_root/assets/sourceos/skills/." "$stage/share/turtle-term/skills/"
cp -R "$repo_root/assets/sourceos/brand/." "$stage/share/turtle-term/brand/"
cp -R "$repo_root/assets/sourceos/desktop/." "$stage/share/turtle-term/desktop/"
cp "$repo_root/LICENSE.md" "$stage/"
cp "$repo_root/THIRD_PARTY_NOTICES.md" "$stage/" 2>/dev/null || true

if [[ "$target" == macos-* ]] || [[ "$(uname -s)" == "Darwin" ]]; then
  chmod +x "$repo_root/packaging/scripts/stage-macos-app.sh"
  "$repo_root/packaging/scripts/stage-macos-app.sh" "$version" "$stage/share/turtle-term" >/dev/null
fi

cat > "$stage/README.md" <<'EOF'
# TurtleTerm Release Artifact

TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench for trusted command execution, terminal receipts, agent delegation, and reproducible operator workflows.

This artifact includes:

- TurtleTerm graphical launcher
- TurtleTerm command wrapper
- TurtleTerm local agent gateway
- TurtleTerm agent CLI
- TurtleTerm tmux bridge
- TurtleTerm mux launcher
- TurtleTerm profile
- TurtleTerm Linux desktop metadata
- TurtleTerm staged macOS app metadata when built for macOS
- TurtleTerm skill manifests
- TurtleTerm turtle icon
- SourceOS terminal documentation
- required license and third-party notices

Install by copying the contents into a prefix such as `/usr/local` or `$HOME/.local`.

Example:

```bash
tar -xzf turtle-term-*.tar.gz
cd turtle-term-*
cp -R bin etc share libexec "$HOME/.local/"
```

Then ensure `$HOME/.local/bin` is on PATH and launch with:

```bash
turtleterm
```
EOF

rm -f "$archive" "$archive.sha256" "$manifest"
tar -C "$out_dir" -czf "$archive" "$(basename "$stage")"
sha256sum "$archive" > "$archive.sha256" 2>/dev/null || shasum -a 256 "$archive" > "$archive.sha256"
python3 "$repo_root/packaging/scripts/write-turtle-term-manifest.py" \
  --version "$version" \
  --target "$target" \
  --archive "$archive" \
  --out "$manifest"

echo "$archive"
