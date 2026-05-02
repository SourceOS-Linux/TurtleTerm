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
mkdir -p "$stage/bin" "$stage/etc/turtle-term" "$stage/share/turtle-term/sourceos"

cp "$repo_root/target/release/wezterm" "$stage/bin/"
cp "$repo_root/target/release/wezterm-gui" "$stage/bin/"
cp "$repo_root/target/release/wezterm-mux-server" "$stage/bin/"
cp "$repo_root/assets/sourceos/bin/turtle-term" "$stage/bin/"
cp "$repo_root/assets/sourceos/bin/sourceos-term" "$stage/bin/"
chmod 0755 "$stage/bin/turtle-term" "$stage/bin/sourceos-term"

cp "$repo_root/assets/sourceos/wezterm.lua" "$stage/etc/turtle-term/wezterm.lua"
cp -R "$repo_root/docs/sourceos/." "$stage/share/turtle-term/sourceos/"
cp "$repo_root/LICENSE.md" "$stage/"
cp "$repo_root/README.md" "$stage/UPSTREAM_WEZTERM_README.md"

cat > "$stage/README.md" <<'EOF'
# TurtleTerm Release Artifact

TurtleTerm is the SourceOS policy-aware agent terminal workbench product built on the WezTerm engine.

This artifact includes:

- wezterm
- wezterm-gui
- wezterm-mux-server
- turtle-term
- sourceos-term compatibility command
- TurtleTerm WezTerm profile
- SourceOS terminal documentation
- upstream WezTerm license and attribution

Install by copying the contents into a prefix such as `/usr/local` or `$HOME/.local`.

Example:

```bash
tar -xzf turtle-term-*.tar.gz
cd turtle-term-*
cp -R bin etc share "$HOME/.local/"
```

Then ensure `$HOME/.local/bin` is on PATH.
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
