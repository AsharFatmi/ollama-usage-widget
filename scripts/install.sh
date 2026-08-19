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
mkdir -p "$APP_DIR"
cp "$BIN" "$APP_DIR/OllamaUsageWidget"

PLIST="$HOME/Library/LaunchAgents/com.asharfatmi.ollama-usage-widget.plist"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.asharfatmi.ollama-usage-widget</string>
    <key>ProgramArguments</key>
    <array><string>$HOME/Applications/ollama-usage-widget/OllamaUsageWidget</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><false/>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/com.asharfatmi.ollama-usage-widget" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed. Menu bar item should appear."
