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

# Copy the SPM-generated resource bundle as a whole into Contents/Resources/.
# `Bundle.module` (used by MacClockApp.registerFonts and any future SPM
# resource lookups) searches relative to the main bundle's Resource URL —
# so MacClock_MacClock.bundle MUST live at Contents/Resources/, not have
# its contents flattened into Contents/Resources/.
SPM_BUNDLE=".build/release/MacClock_MacClock.bundle"
if [ -d "$SPM_BUNDLE" ]; then
    cp -R "$SPM_BUNDLE" "$RESOURCES_DIR/"
else
    echo "ERROR: SPM resource bundle not found at $SPM_BUNDLE" >&2
    exit 1
fi

# Copy AppIcon (not part of the SPM resource bundle — referenced directly
# from Info.plist via CFBundleIconFile, so it lives at Contents/Resources/
# alongside the SPM bundle).
if [ -f "MacClock/Resources/AppIcon.icns" ]; then
    cp "MacClock/Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

# Copy authoritative Info.plist (single source of truth in MacClock/)
cp "MacClock/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "Built $APP_DIR"
echo "Run with: open $APP_DIR"
