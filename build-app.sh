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

# Copy the SPM-bundled resources (Backgrounds, Fonts) directly into
# Contents/Resources/. The runtime accessor in MacClockApp.registerFonts
# checks Bundle.main first, so this is the preferred .app layout. We
# deliberately do NOT copy MacClock_MacClock.bundle into the .app root —
# that's where SwiftPM's resource_bundle_accessor.swift expects it, but
# it conflicts with codesign ("unsealed contents present in the bundle
# root"). Bundle.module is only used as a fallback in dev workflows.
SPM_BUNDLE=".build/release/MacClock_MacClock.bundle"
if [ ! -d "$SPM_BUNDLE" ]; then
    echo "ERROR: SPM resource bundle not found at $SPM_BUNDLE" >&2
    exit 1
fi
for sub in Backgrounds Fonts; do
    if [ -d "$SPM_BUNDLE/$sub" ]; then
        cp -R "$SPM_BUNDLE/$sub" "$RESOURCES_DIR/"
    fi
done

# Copy AppIcon (not part of the SPM resource bundle — referenced from
# Info.plist via CFBundleIconFile and read by AppKit, which uses
# Bundle.main).
if [ -f "MacClock/Resources/AppIcon.icns" ]; then
    cp "MacClock/Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

# Copy authoritative Info.plist (single source of truth in MacClock/)
cp "MacClock/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "Built $APP_DIR"
echo "Run with: open $APP_DIR"
