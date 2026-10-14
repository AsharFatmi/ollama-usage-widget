# 🦙 Ollama Usage Widget

A native macOS menu bar widget that tracks your **Ollama Cloud** usage (weekly & session quota rings, 7-day request totals) and your **local Ollama** server state — right from the menu bar.

<p align="center">
  <img src="https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/pill.png" alt="Menu bar pill preview" width="640">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/popover.png" alt="Popover preview" width="420">
</p>

## Features

- **Menu bar pill** — black iPhone-island style pill showing session % + weekly % at a glance
- **Weekly & Session rings** — hollow progress rings with percentages centered inside
- **Request totals** — requests over the last 7 days, plus cost when your plan reports it
- **7-day activity chart** — built from Ollama's own usage buckets, live from day one
- **Local Ollama state** — loaded models and VRAM usage via `GET /api/ps`
- **Auto-refresh** — polls every 5 minutes; manual refresh via the top-right icon
- **Collapsible sections** — Ollama Cloud / Local Ollama, state remembered
- **Secure key storage** — API key held in the macOS Keychain (with `.env` fallback)

## Requirements

- macOS 14.0+ (Apple Silicon)
- [Ollama](https://ollama.com) account with Cloud usage enabled
- An Ollama Cloud API key

> ⚠️ **Note:** The widget reads Ollama's cloud usage endpoints (`GET /api/balance` and `GET /api/usage?range=7d`). Ollama doesn't version these, and the response shape already changed once — that fix shipped as **v1.0.1**. If something breaks, please open an issue.
>
> Per-model breakdowns were removed from Ollama's API (their docs say "coming soon"), so that view is unavailable for now.

## Install

### One line (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash
```

Downloads the latest release DMG, installs to `/Applications`, and registers a LaunchAgent so the widget starts at login and restarts if it crashes. Because the file comes via `curl` (no quarantine attribute), you won't see a Gatekeeper "unidentified developer" prompt.

Already installed? Re-run the same command to upgrade. Remove with `curl -fsSL …/install.sh | bash -s uninstall`.

### Homebrew

```bash
brew tap asharfatmi/tap
brew install --cask ollama-usage-widget
```

### From source

```bash
git clone https://github.com/AsharFatmi/ollama-usage-widget.git
cd ollama-usage-widget
./scripts/deploy.sh
```

The script builds with SwiftPM, wraps the binary in an `.app` bundle, and registers a LaunchAgent so the widget starts at login and restarts if it crashes.

> **Toolchain note:** macOS Command Line Tools can ship a stale SwiftPM manifest library that breaks `swift build`. If you hit manifest/linker errors, install Swift via Homebrew (`brew install swift`) and ensure `/opt/homebrew/bin` comes first in `PATH`.

### Manual

```bash
swift build -c release
cp -R .build/release/OllamaUsageWidget.app ~/Applications/
open ~/Applications/OllamaUsageWidget.app
```

## Set your API key

1. Click the 🦙 pill → **Set Key…**
2. Paste your Ollama Cloud API key (stored in the macOS Keychain)

**Alternative:** create `~/.ollama-usage-widget/.env` (or `~/.ollama-usage-widget.env`) containing:

```
OLLAMA_API_KEY=ollama-xxxxxxxx
```

For compatibility with Hermes-agent environments, `~/.hermes/.env` is also read as a fallback.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash -s uninstall
```

Or manually:

```bash
launchctl bootout gui/$(id -u)/com.asharfatmi.ollama-usage-widget
rm -rf ~/Applications/ollama-usage-widget
rm -rf /Applications/OllamaUsageWidget.app
rm ~/Library/LaunchAgents/com.asharfatmi.ollama-usage-widget.plist
```

## How it works

| Data | Source |
|------|--------|
| Weekly / session quota (used %) | `GET https://ollama.com/api/balance` (Bearer token) |
| Requests + cost (7d) | `GET https://ollama.com/api/usage?range=7d` (Bearer token) |
| 7-day activity chart | the `buckets` from that same usage request |
| Local models + VRAM | `GET http://localhost:11434/api/ps` |

The API key is never stored in the app bundle — it lives in your Keychain or env file only.

## License

[MIT](LICENSE) © 2026 Ashar Fatmi
