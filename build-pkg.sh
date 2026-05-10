#!/usr/bin/env bash
set -euo pipefail

# Build a multi-step macOS Installer package (.pkg) from MacClock.app.
# Run after ./build-app.sh (which produces MacClock.app in the repo root).
#
# Output: MacClock-<version>.pkg in the repo root.

if [ ! -d "MacClock.app" ]; then
    echo "ERROR: MacClock.app not found. Run ./build-app.sh first." >&2
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" MacClock.app/Contents/Info.plist)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" MacClock.app/Contents/Info.plist)
PKG_OUT="MacClock-${VERSION}.pkg"

echo "Building ${PKG_OUT} (id=${BUNDLE_ID}, version=${VERSION})"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Stage the install layout — files end up at /Applications/MacClock.app
# on the target system because pkgbuild treats $WORK/payload as the root.
mkdir -p "$WORK/payload/Applications"
cp -R MacClock.app "$WORK/payload/Applications/"

# Build the component package.
COMPONENT="$WORK/MacClock-component.pkg"
pkgbuild \
    --root "$WORK/payload" \
    --identifier "$BUNDLE_ID" \
    --version "$VERSION" \
    --install-location "/" \
    --scripts ".github/pkg/scripts" \
    "$COMPONENT"

# Copy LICENSE alongside welcome/conclusion so productbuild can find them.
RES="$WORK/resources"
mkdir -p "$RES"
cp .github/pkg/resources/welcome.html "$RES/"
cp .github/pkg/resources/conclusion.html "$RES/"
cp LICENSE "$RES/LICENSE.txt"

# Wrap the component package with the multi-step UI.
productbuild \
    --distribution ".github/pkg/distribution.xml" \
    --resources "$RES" \
    --package-path "$WORK" \
    "$PKG_OUT"

echo ""
echo "Built $PKG_OUT ($(/usr/bin/du -h "$PKG_OUT" | cut -f1))"
echo "Open with: open $PKG_OUT"
