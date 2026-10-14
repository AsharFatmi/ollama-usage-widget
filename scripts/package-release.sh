#!/bin/bash
# Build a release .app bundle + DMG for a given version.
#
#   scripts/package-release.sh 1.0.1
#
# Output: dist/OllamaUsageWidget-<version>.dmg  (SHA-256 printed at the end)
# Upload the DMG to the matching GitHub release tag (v<version>).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "usage: scripts/package-release.sh <version>   e.g. scripts/package-release.sh 1.0.1" >&2
    exit 2
fi

# Worker PATH may resolve bare 'swift' to a broken CLT copy.
if [ -x /opt/homebrew/bin/swift ]; then
    SWIFT=/opt/homebrew/bin/swift
else
    SWIFT=swift
fi

"$SWIFT" build -c release

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/OllamaUsageWidget.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/OllamaUsageWidget "$APP/Contents/MacOS/OllamaUsageWidget"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>OllamaUsageWidget</string>
    <key>CFBundleDisplayName</key><string>Ollama Usage Widget</string>
    <key>CFBundleIdentifier</key><string>com.asharfatmi.ollama-usage-widget</string>
    <key>CFBundleExecutable</key><string>OllamaUsageWidget</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

# Drag-to-install layout
ln -s /Applications "$STAGE/Applications"

mkdir -p dist
OUT="dist/OllamaUsageWidget-$VERSION.dmg"
rm -f "$OUT"
hdiutil create -volname "Ollama Usage Widget" -srcfolder "$STAGE" -ov -format UDZO -quiet "$OUT"

echo "Built $OUT"
shasum -a 256 "$OUT"
