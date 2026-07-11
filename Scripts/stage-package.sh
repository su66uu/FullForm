#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE_DIR="$REPO_ROOT/.build/stage"

FULLFORM_BINARY="$REPO_ROOT/.build/release/fullform"
WORKFLOW_SOURCE="$REPO_ROOT/Workflows/Look Up FullForm.workflow"
GLOSSARY_SOURCE="$REPO_ROOT/Resources/fullform.json"

swift build -c release --package-path "$REPO_ROOT"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/bin"
mkdir -p "$STAGE_DIR/services"
mkdir -p "$STAGE_DIR/app-support"
mkdir -p "$STAGE_DIR/share/fullform"

install -m 755 "$FULLFORM_BINARY" "$STAGE_DIR/bin/fullform"
cp -R "$WORKFLOW_SOURCE" "$STAGE_DIR/services/"
install -m 644 "$GLOSSARY_SOURCE" "$STAGE_DIR/app-support/fullform.json"
cp -R "$WORKFLOW_SOURCE" "$STAGE_DIR/share/fullform/"
install -m 644 "$GLOSSARY_SOURCE" "$STAGE_DIR/share/fullform/fullform.json"

echo "Staged FullForm package inputs in $STAGE_DIR"
