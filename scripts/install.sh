#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Worker PATH has /usr/bin before /opt/homebrew/bin, so bare 'swift' can
# resolve to a broken CLT copy. Prefer the Homebrew toolchain explicitly.
if [ -x /opt/homebrew/bin/swift ]; then
    SWIFT=/opt/homebrew/bin/swift
else
    SWIFT=swift
fi

"$SWIFT" build -c release
BIN=".build/release/OllamaUsageWidget"
APP_DIR="$HOME/Applications/ollama-usage-widget"

# Build a proper .app bundle so LaunchServices runs the binary detached from
# any terminal (bare binaries launched via terminal die with it).
APP_BUNDLE="$APP_DIR/OllamaUsageWidget.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cp "$BIN" "$APP_BUNDLE/Contents/MacOS/OllamaUsageWidget"
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>OllamaUsageWidget</string>
    <key>CFBundleDisplayName</key><string>Ollama Usage Widget</string>
    <key>CFBundleIdentifier</key><string>com.asharfatmi.ollama-usage-widget</string>
    <key>CFBundleExecutable</key><string>OllamaUsageWidget</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF
# Keep a plain copy too (used by any direct launcher)
cp "$BIN" "$APP_DIR/OllamaUsageWidget"

PLIST="$HOME/Library/LaunchAgents/com.asharfatmi.ollama-usage-widget.plist"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.asharfatmi.ollama-usage-widget</string>
    <key>ProgramArguments</key>
    <array><string>$APP_BUNDLE/Contents/MacOS/OllamaUsageWidget</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/com.asharfatmi.ollama-usage-widget" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed (detached, KeepAlive). Menu bar item should appear."
