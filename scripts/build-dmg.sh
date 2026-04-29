#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/Stash.xcodeproj"
SCHEME="Stash"
CONFIG="Release"
BUILD_DIR="$PROJECT_DIR/build"

VERSION=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | head -1 | awk '{print $3}')

build_and_dmg() {
  local arch="$1"
  local label="$2"
  local build_dir="$BUILD_DIR/$arch"
  local app_path="$build_dir/Build/Products/$CONFIG/Stash.app"
  local dmg_name="Stash-v${VERSION}-${label}.dmg"
  local dmg_path="$PROJECT_DIR/$dmg_name"

  echo "=== Building Stash ($label, $arch) ==="
  xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -derivedDataPath "$build_dir" \
    ARCHS="$arch" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    build

  if [ ! -d "$app_path" ]; then
    echo "ERROR: $app_path not found"
    exit 1
  fi

  echo "=== Creating $dmg_name ==="
  rm -f "$dmg_path"
  hdiutil create -volname "Stash" \
    -srcfolder "$app_path" \
    -ov -format UDZO \
    "$dmg_path"

  echo "=== Done: $dmg_path ==="
  ls -lh "$dmg_path"
}

build_and_dmg "arm64" "AppleSilicon"
build_and_dmg "x86_64" "Intel"

echo ""
echo "=== All builds complete ==="
ls -lh "$PROJECT_DIR"/Stash-v${VERSION}-*.dmg
