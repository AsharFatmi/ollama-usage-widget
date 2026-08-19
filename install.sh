#!/bin/bash
# Ollama Usage Widget — one-line installer
#   curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash
#
# Downloads the latest release DMG from GitHub, installs the app, and
# registers a LaunchAgent so the widget starts at login and stays alive.
# Because curl does not set the quarantine attribute, no Gatekeeper
# "unidentified developer" prompt appears.
#
#   install.sh            install (or upgrade) the widget
#   install.sh uninstall   remove the widget and its LaunchAgent
set -euo pipefail

APP_NAME="OllamaUsageWidget"
BUNDLE_ID="com.asharfatmi.ollama-usage-widget"
REPO="AsharFatmi/ollama-usage-widget"
FALLBACK_VERSION="v1.0.0"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"

# arm64-only build: bail with a clear message on Intel instead of a cryptic error.
if [ "$(uname -m)" != "arm64" ]; then
    echo "error: Ollama Usage Widget is built for Apple Silicon (arm64) only." >&2
    echo "Your Mac is $(uname -m). No Intel build is available." >&2
    exit 1
fi

find_dmg_url() {
    # Latest release from the GitHub API; fall back to a pinned version if
    # the API is rate-limited or unreachable.
    local json url
    json=$(curl -fsSL --max-time 15 "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null || true)
    url=$(printf '%s' "$json" | grep -oE 'https://[^"]+\.dmg' | head -n1)
    if [ -z "$url" ]; then
        echo "warning: could not query latest release, using $FALLBACK_VERSION" >&2
        url="https://github.com/$REPO/releases/download/$FALLBACK_VERSION/$APP_NAME-$FALLBACK_VERSION.dmg"
    fi
    printf '%s' "$url"
}

uninstall() {
    echo "==> Stopping widget"
    launchctl bootout "gui/$(id -u)/$BUNDLE_ID" 2>/dev/null || true
    pkill -x "$APP_NAME" 2>/dev/null || true
    rm -f "$LAUNCH_AGENT"
    rm -rf "/Applications/$APP_NAME.app"
    rm -rf "$HOME/Applications/$APP_NAME.app"
    rm -rf "$HOME/Applications/ollama-usage-widget"   # dev/deploy.sh location
    echo "==> Uninstalled."
}

if [ "${1:-}" = "uninstall" ]; then
    uninstall
    exit 0
fi

# --- stop any running instance and old agent before replacing -------------
echo "==> Stopping existing widget (if any)"
launchctl bootout "gui/$(id -u)/$BUNDLE_ID" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true

# --- download -----------------------------------------------------------------
DMG_URL=$(find_dmg_url)
echo "==> Downloading $DMG_URL"
TMP_DMG="$(mktemp -d)/$APP_NAME.dmg"
trap 'rm -rf "$(dirname "$TMP_DMG")"' EXIT
curl -fsSL --retry 3 -o "$TMP_DMG" "$DMG_URL"

# --- mount + copy --------------------------------------------------------------
echo "==> Installing to /Applications"
# Volume name contains spaces ("Ollama Usage Widget") — capture the whole
# /Volumes/... path, not just the last whitespace-delimited field.
VOL=$(hdiutil attach -nobrowse -readonly "$TMP_DMG" | grep -o '/Volumes/.*' | tail -n1 | sed 's/[[:space:]]*$//')
trap 'hdiutil detach "$VOL" -quiet 2>/dev/null || true; rm -rf "$(dirname "$TMP_DMG")"' EXIT

DEST="/Applications"
if [ ! -w "$DEST" ]; then
    echo "warning: /Applications not writable, installing to ~/Applications instead" >&2
    DEST="$HOME/Applications"
fi
mkdir -p "$DEST"
ditto "$VOL/$APP_NAME.app" "$DEST/$APP_NAME.app"
xattr -dr com.apple.quarantine "$DEST/$APP_NAME.app" 2>/dev/null || true
hdiutil detach "$VOL" -quiet
trap 'rm -rf "$(dirname "$TMP_DMG")"' EXIT

# --- LaunchAgent (start at login, keep alive) --------------------------------
echo "==> Registering launch agent"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$BUNDLE_ID</string>
    <key>ProgramArguments</key>
    <array><string>$DEST/$APP_NAME.app/Contents/MacOS/$APP_NAME</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
</dict>
</plist>
EOF
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"

echo "==> Done. The 🦙 pill should appear in your menu bar."
echo "    Next: right-click the pill → Set Key… to add your Ollama Cloud API key."
echo "    (Tip: keep the installer around to re-run for updates: curl -fsSL https://raw.githubusercontent.com/$REPO/master/install.sh | bash)"
