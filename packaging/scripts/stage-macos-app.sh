#!/usr/bin/env bash
set -euo pipefail

version="${1:-0.1.0}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${2:-$repo_root/dist}"
app_root="$out_dir/TurtleTerm.app"
contents="$app_root/Contents"
macos="$contents/MacOS"
resources="$contents/Resources"

rm -rf "$app_root"
mkdir -p "$macos" "$resources" "$contents/libexec/turtle-term" "$contents/etc/turtle-term" "$contents/share/turtle-term"

cp "$repo_root/assets/sourceos/macos/Info.plist" "$contents/Info.plist"
python3 - "$contents/Info.plist" "$version" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
version = sys.argv[2]
text = path.read_text(encoding='utf-8')
text = text.replace('<string>0.1.0</string>', f'<string>{version}</string>')
path.write_text(text, encoding='utf-8')
PY

cp "$repo_root/target/release/wezterm-gui" "$contents/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm" "$contents/libexec/turtle-term/"
cp "$repo_root/target/release/wezterm-mux-server" "$contents/libexec/turtle-term/"
cp "$repo_root/assets/sourceos/turtleterm.lua" "$contents/etc/turtle-term/turtleterm.lua"
cp "$repo_root/assets/sourceos/brand/turtleterm-icon.svg" "$resources/turtleterm-icon.svg"
cp "$repo_root/LICENSE.md" "$contents/"
cp "$repo_root/THIRD_PARTY_NOTICES.md" "$contents/" 2>/dev/null || true
cp -R "$repo_root/docs/sourceos" "$contents/share/turtle-term/sourceos"
cp -R "$repo_root/assets/sourceos/skills" "$contents/share/turtle-term/skills"

cat > "$macos/turtleterm" <<'EOF'
#!/usr/bin/env sh
set -eu
app_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
export TURTLE_TERM_RUNTIME_DIR="$app_dir/libexec/turtle-term"
export TURTLETERM_CONFIG="$app_dir/etc/turtle-term/turtleterm.lua"
export SOURCEOS_TERMINAL_FRONTEND="${SOURCEOS_TERMINAL_FRONTEND:-turtle-term}"
exec "$app_dir/libexec/turtle-term/wezterm-gui" --config-file "$TURTLETERM_CONFIG" "$@"
EOF
chmod 0755 "$macos/turtleterm"

echo "$app_root"
