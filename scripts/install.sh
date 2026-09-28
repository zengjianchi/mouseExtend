#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

# Build first if needed
if [ ! -d "$DIR/MouseExtend.app" ]; then
    bash "$DIR/scripts/build.sh"
fi

INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

echo "Installing MouseExtend.app to $INSTALL_DIR..."
# Kill any running instances
pkill -f "MouseExtend.app/Contents/MacOS/MouseExtend" 2>/dev/null || true

rm -rf "$INSTALL_DIR/MouseExtend.app"
cp -R "$DIR/MouseExtend.app" "$INSTALL_DIR/"

echo "Installed successfully to $INSTALL_DIR/MouseExtend.app"
echo "Launching MouseExtend..."
open "$INSTALL_DIR/MouseExtend.app"
