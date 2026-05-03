#!/usr/bin/env bash
set -euo pipefail

repo="${TURTLE_TERM_REPO:-SourceOS-Linux/TurtleTerm}"
prefix="${TURTLE_TERM_PREFIX:-$HOME/.local}"
version="${TURTLE_TERM_VERSION:-latest}"
use_brew="${TURTLE_TERM_USE_BREW:-auto}"

log() { printf '%s\n' "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1; }

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$os:$arch" in
  darwin:arm64) target="macos-arm64" ;;
  darwin:x86_64) target="macos-x86_64" ;;
  linux:x86_64|linux:amd64) target="linux-x86_64" ;;
  linux:aarch64|linux:arm64) target="linux-arm64" ;;
  *) log "unsupported platform: $os/$arch"; exit 2 ;;
esac

if [ "$use_brew" != "never" ] && need brew; then
  log "Homebrew detected. Trying TurtleTerm Homebrew install first."
  if brew install --HEAD SourceOS-Linux/tap/turtle-term; then
    log "TurtleTerm installed with Homebrew."
    exit 0
  fi
  if [ "$use_brew" = "always" ]; then
    log "Homebrew install failed and TURTLE_TERM_USE_BREW=always."
    exit 1
  fi
  log "Homebrew install failed; falling back to release artifact install."
fi

need curl || { log "curl is required for release artifact install"; exit 1; }
need tar || { log "tar is required for release artifact install"; exit 1; }

if [ "$version" = "latest" ]; then
  api="https://api.github.com/repos/$repo/releases/latest"
  tag="$(curl -fsSL "$api" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)"
  if [ -z "$tag" ]; then
    log "could not determine latest TurtleTerm release for $repo"
    log "set TURTLE_TERM_VERSION=turtle-term-vX.Y.Z or use Homebrew after the tap is published"
    exit 1
  fi
else
  tag="$version"
fi

asset="turtle-term-$tag-$target.tar.gz"
url="https://github.com/$repo/releases/download/$tag/$asset"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "Downloading $url"
curl -fL "$url" -o "$tmp/$asset"

mkdir -p "$prefix"
tar -xzf "$tmp/$asset" -C "$tmp"
root="$(find "$tmp" -maxdepth 1 -type d -name 'turtle-term-*' | head -n 1)"
if [ -z "$root" ]; then
  log "release archive did not contain a turtle-term directory"
  exit 1
fi

mkdir -p "$prefix/bin" "$prefix/etc" "$prefix/share" "$prefix/libexec"
cp -R "$root/bin/." "$prefix/bin/"
cp -R "$root/etc/." "$prefix/etc/"
cp -R "$root/share/." "$prefix/share/"
cp -R "$root/libexec/." "$prefix/libexec/"

log "TurtleTerm installed to $prefix"
log "Ensure $prefix/bin is on PATH."
log "Launch with: turtleterm"
log "Test with: turtle-term run -- echo turtle-term-ok"
