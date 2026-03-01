#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/build/说话.app/Contents"

# Build
cd "$ROOT/app"
xcodebuild -scheme Shuohua -configuration Release -destination 'platform=macOS' \
  -derivedDataPath DerivedData build -quiet

# Create .app bundle
rm -rf "$ROOT/build/说话.app"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources"
cp DerivedData/Build/Products/Release/Shuohua "$APP_DIR/MacOS/"
cp Resources/Info.plist "$APP_DIR/"
cp Resources/AppIcon.icns "$APP_DIR/Resources/" 2>/dev/null || true
cp -R DerivedData/Build/Products/Release/mlx-swift_Cmlx.bundle "$APP_DIR/Resources/"

# Ad-hoc sign with a stable designated requirement so TCC permissions
# (Accessibility/Microphone) survive local rebuilds.
codesign --force --sign - \
  --entitlements Resources/Shuohua.entitlements \
  --options runtime \
  -r='designated => identifier com.shuohua.app' \
  "$ROOT/build/说话.app"

echo "✓ build/说话.app (signed)"
