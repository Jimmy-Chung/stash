#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/Stash.xcodeproj"
SCHEME="Stash"
CONFIG="Release"
BUILD_DIR="$PROJECT_DIR/build"
DMG_NAME="Stash.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"
APP_PATH="$BUILD_DIR/Build/Products/$CONFIG/Stash.app"

echo "=== Building Stash for Release ==="
xcodebuild -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  build

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: $APP_PATH not found"
  exit 1
fi

echo "=== Removing old DMG ==="
rm -f "$DMG_PATH"

echo "=== Creating DMG ==="
hdiutil create -volname "Stash" \
  -srcfolder "$APP_PATH" \
  -ov -format UDZO \
  "$DMG_PATH"

echo "=== Done: $DMG_PATH ==="
ls -lh "$DMG_PATH"
