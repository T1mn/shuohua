#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="0.1.0"
DMG_NAME="说话-${VERSION}.dmg"
STAGING="$ROOT/dist/dmg-staging"

rm -rf "$STAGING" "$ROOT/dist/$DMG_NAME"
mkdir -p "$STAGING"

cp -R "$ROOT/build/说话.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "说话" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$ROOT/dist/$DMG_NAME"

rm -rf "$STAGING"
echo "✓ dist/$DMG_NAME"
