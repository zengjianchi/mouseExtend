#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

if [ ! -d "$DIR/MouseExtend.app" ]; then
    bash "$DIR/scripts/build.sh"
fi

# Kill previous instance if running
pkill -f "MouseExtend.app/Contents/MacOS/MouseExtend" 2>/dev/null || true

echo "Starting MouseExtend..."
open "$DIR/MouseExtend.app"
