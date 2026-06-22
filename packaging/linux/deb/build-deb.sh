#!/usr/bin/env bash
# Build a .deb for TurtleTerm
# Usage: ./build-deb.sh [version] [arch]
# Requires: dpkg-deb, already-built stage in ./staging/

set -euo pipefail

VERSION="${1:-1.4.0}"
ARCH="${2:-amd64}"
PACKAGE="turtleterm"
STAGE_DIR="${STAGE_DIR:-$(mktemp -d)}"
DEB_ROOT="$STAGE_DIR/DEBIAN"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "Building $PACKAGE ${VERSION} (${ARCH})..."

# Stage the package
TURTLE_TERM_STAGE_PREFIX="$STAGE_DIR/usr" \
TURTLE_TERM_ETC_DIR="$STAGE_DIR/etc" \
TURTLE_TERM_RUNTIME_PREFIX="/usr" \
TURTLE_TERM_RUNTIME_ETC_DIR="/etc" \
  bash "$REPO_ROOT/packaging/scripts/stage-linux-package.sh"

# Write DEBIAN metadata
mkdir -p "$DEB_ROOT"

sed "s/^Version:.*/Version: $VERSION/; s/^Architecture:.*/Architecture: $ARCH/" \
  "$SCRIPT_DIR/control" > "$DEB_ROOT/control"

cp "$SCRIPT_DIR/postinst" "$DEB_ROOT/postinst"
cp "$SCRIPT_DIR/prerm"    "$DEB_ROOT/prerm"
cp "$SCRIPT_DIR/postrm"   "$DEB_ROOT/postrm"
cp "$SCRIPT_DIR/conffiles" "$DEB_ROOT/conffiles"

chmod 755 "$DEB_ROOT/postinst" "$DEB_ROOT/prerm" "$DEB_ROOT/postrm"

# Build
OUTPUT="${PACKAGE}_${VERSION}_${ARCH}.deb"
dpkg-deb --build --root-owner-group "$STAGE_DIR" "$OUTPUT"
echo "Built: $OUTPUT"
