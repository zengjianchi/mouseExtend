#!/bin/bash
set -e

# Change to script's parent directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "=========================================="
echo "  Building MouseExtend.app for macOS"
echo "=========================================="

export DEVELOPER_DIR="/Library/Developer/CommandLineTools"

echo "[1/4] Compiling release executable..."
swift build -c release

APP_NAME="MouseExtend.app"
APP_DIR="$DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "[2/4] Assembling .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/MouseExtend" "$MACOS_DIR/MouseExtend"
chmod +x "$MACOS_DIR/MouseExtend"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy AppIcon.icns
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | awk -F'"' '{print $2}')
if [ -n "$SIGNING_IDENTITY" ]; then
    echo "[3/4] Code signing with identity: $SIGNING_IDENTITY"
    codesign --force --deep --identifier "com.antigravity.MouseExtend" --sign "$SIGNING_IDENTITY" "$APP_DIR"
else
    echo "[3/4] Code signing with ad-hoc signature..."
    codesign --force --deep --identifier "com.antigravity.MouseExtend" -s - "$APP_DIR"
fi
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true

echo "[4/4] Done!"
echo "------------------------------------------"
echo "Build succeeded: $APP_DIR"
echo "You can launch the app with: open '$APP_DIR'"
echo "=========================================="
