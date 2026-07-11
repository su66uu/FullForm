#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE_DIR="$REPO_ROOT/.build/stage"
PKG_ROOT="$REPO_ROOT/.build/pkg-root"
PKG_OUTPUT_DIR="$REPO_ROOT/.build/packages"
PKG_OUTPUT="$PKG_OUTPUT_DIR/FullForm.pkg"

"$REPO_ROOT/Scripts/stage-package.sh"

rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT/usr/local/bin"
mkdir -p "$PKG_ROOT/Library/Services"
mkdir -p "$PKG_OUTPUT_DIR"

install -m 755 "$STAGE_DIR/bin/fullform" "$PKG_ROOT/usr/local/bin/fullform"
cp -R "$STAGE_DIR/services/Look Up FullForm.workflow" "$PKG_ROOT/Library/Services/"
xattr -cr "$PKG_ROOT"
xattr -d -r com.apple.provenance "$PKG_ROOT" 2>/dev/null || true

pkgbuild \
    --root "$PKG_ROOT" \
    --identifier "com.konic.fullform" \
    --version "0.1.0" \
    --install-location "/" \
    --ownership recommended \
    --filter '(^|/)\.DS_Store$' \
    --filter '(^|/)\._[^/]+$' \
    --filter '(^|/)\.svn($|/)' \
    --filter '(^|/)CVS($|/)' \
    "$PKG_OUTPUT"

echo "Built $PKG_OUTPUT"
