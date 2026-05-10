#!/usr/bin/env bash
# Convenience installer that copies MacClock.app into /Applications and
# strips the quarantine flag so macOS Gatekeeper allows the (ad-hoc-signed,
# non-notarised) app to launch normally on first run.

set -euo pipefail
DMG_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DMG_DIR/MacClock.app"
DEST="/Applications/MacClock.app"

echo "Installing MacClock to /Applications…"
[ -d "$DEST" ] && rm -rf "$DEST"
cp -R "$APP" "$DEST"

echo "Removing quarantine attribute…"
xattr -cr "$DEST" || true

echo "Done. Launching MacClock…"
open "$DEST"
