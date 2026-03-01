#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="说话.app"
BUILD_APP="$ROOT/build/$APP_NAME"
TARGET_APP="/Applications/$APP_NAME"
BUNDLE_ID="com.shuohua.app"

usage() {
  cat <<EOF
Usage: bash scripts/rebuild-open.sh [--reset-tcc]

Options:
  --reset-tcc   Reset Accessibility + Microphone permissions for ${BUNDLE_ID}
                (for troubleshooting only; you will be prompted to grant permissions again)
EOF
}

RESET_TCC=0
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
if [[ "${1:-}" == "--reset-tcc" ]]; then
  RESET_TCC=1
elif [[ -n "${1:-}" ]]; then
  echo "Unknown option: $1" >&2
  usage >&2
  exit 1
fi

echo "==> Quitting running app (if any)"
osascript -e 'tell application id "com.shuohua.app" to quit' >/dev/null 2>&1 || true
sleep 0.5
if pgrep -x "Shuohua" >/dev/null 2>&1; then
  pkill -x "Shuohua" || true
fi

echo "==> Building app"
bash "$ROOT/scripts/build.sh"

echo "==> Installing to /Applications"
if [[ -w "/Applications" ]]; then
  ditto "$BUILD_APP" "$TARGET_APP"
else
  sudo /usr/bin/ditto "$BUILD_APP" "$TARGET_APP"
fi

if [[ "$RESET_TCC" -eq 1 ]]; then
  echo "==> Resetting TCC permissions for ${BUNDLE_ID}"
  tccutil reset Accessibility "$BUNDLE_ID" || true
  tccutil reset Microphone "$BUNDLE_ID" || true
fi

echo "==> Opening app"
open "$TARGET_APP"

echo "Done: $TARGET_APP"
