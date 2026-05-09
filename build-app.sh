#!/bin/bash
set -euo pipefail

# Build the release executable
swift build -c release

# Create app bundle structure
APP_NAME="MacClock"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp ".build/release/$APP_NAME" "$MACOS_DIR/"

# Copy resources from the build (SPM bundle)
if [ -d ".build/release/MacClock_MacClock.bundle/Contents/Resources" ]; then
    cp -R ".build/release/MacClock_MacClock.bundle/Contents/Resources/"* "$RESOURCES_DIR/"
fi

# Also copy from source if needed
if [ -d "MacClock/Resources" ]; then
    cp -R "MacClock/Resources/"* "$RESOURCES_DIR/"
fi

# Copy authoritative Info.plist (single source of truth in MacClock/)
cp "MacClock/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "Built $APP_DIR"
echo "Run with: open $APP_DIR"
