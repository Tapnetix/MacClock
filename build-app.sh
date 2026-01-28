#!/bin/bash

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

# Copy resources from the build
if [ -d ".build/release/MacClock_MacClock.bundle/Contents/Resources" ]; then
    cp -R ".build/release/MacClock_MacClock.bundle/Contents/Resources/"* "$RESOURCES_DIR/"
fi

# Also copy from source if needed
if [ -d "MacClock/Resources" ]; then
    cp -R "MacClock/Resources/"* "$RESOURCES_DIR/"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacClock</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.MacClock</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacClock</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>ATSApplicationFontsPath</key>
    <string>Fonts</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>MacClock needs your location to show local weather conditions.</string>
    <key>NSLocationUsageDescription</key>
    <string>MacClock needs your location to show local weather conditions.</string>
</dict>
</plist>
EOF

echo "Built $APP_DIR"
echo "Run with: open $APP_DIR"
