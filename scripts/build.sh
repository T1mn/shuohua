#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/build/说话.app/Contents"

# Build
cd "$ROOT/app"
xcodebuild -scheme Shuohua -destination 'platform=macOS' \
  -derivedDataPath DerivedData build -quiet

# Create .app bundle
rm -rf "$ROOT/build/说话.app"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources"
cp DerivedData/Build/Products/Debug/Shuohua "$APP_DIR/MacOS/"
cp Resources/Info.plist "$APP_DIR/"

echo "✓ build/说话.app"
