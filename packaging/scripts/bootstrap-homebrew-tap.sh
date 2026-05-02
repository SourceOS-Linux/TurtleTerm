#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tap_repo="${TURTLE_TERM_TAP_REPO:-SourceOS-Linux/homebrew-tap}"
tap_name="${TURTLE_TERM_TAP_NAME:-SourceOS-Linux/tap}"

if ! command -v brew >/dev/null 2>&1; then
  echo "error: brew is required" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh is required to create/push the tap repo" >&2
  exit 1
fi

if brew --repository "$tap_name" >/dev/null 2>&1; then
  tap_path="$(brew --repository "$tap_name")"
else
  brew tap-new "$tap_repo"
  tap_path="$(brew --repository "$tap_name")"
fi

mkdir -p "$tap_path/Formula" "$tap_path/.github/workflows"
cp "$repo_root/packaging/homebrew/Formula/turtle-term.rb" "$tap_path/Formula/turtle-term.rb"
cp "$repo_root/packaging/homebrew/README.md" "$tap_path/README.md"
cp "$repo_root/packaging/homebrew/.github/workflows/test-formula.yml" "$tap_path/.github/workflows/test-formula.yml"

cd "$tap_path"
git add Formula/turtle-term.rb README.md .github/workflows/test-formula.yml
if git diff --cached --quiet; then
  echo "tap already up to date: $tap_path"
else
  git commit -m "Add TurtleTerm Homebrew formula"
fi

if gh repo view "$tap_repo" >/dev/null 2>&1; then
  git remote remove origin >/dev/null 2>&1 || true
  git remote add origin "https://github.com/$tap_repo.git"
  git push -u origin HEAD:main
else
  gh repo create "$tap_repo" --public --source . --push
fi

echo "Tap ready. Test with:"
echo "  brew install --HEAD $tap_name/turtle-term"
echo "  turtle-term run -- echo turtle-term-ok"
