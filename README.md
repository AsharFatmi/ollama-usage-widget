# 🦙 Ollama Usage Widget

A native macOS menu bar widget that tracks your **Ollama Cloud** usage (weekly & session quotas, per-model request counts, cost) and your **local Ollama** server state — right from the menu bar.

![Popover preview](https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/popover.png)

## Features

- **Menu bar pill** — black iPhone-island style pill showing session % + weekly % at a glance
- **Weekly & Session rings** — hollow progress rings with percentages centered inside
- **Activity by model** — horizontal bar chart of request counts per model
- **7-day activity chart** — usage trend over the last week (day-of-month labels)
- **Local Ollama state** — loaded models and VRAM usage via `GET /api/ps`
- **Auto-refresh** — polls every 5 minutes; manual refresh via the top-right icon
- **Collapsible sections** — Ollama Cloud / Local Ollama, state remembered
- **Secure key storage** — API key held in the macOS Keychain (with `.env` fallback)

## Requirements

- macOS 14.0+ (Apple Silicon or Intel)
- [Ollama](https://ollama.com) account with Cloud usage enabled
- An Ollama Cloud API key

> ⚠️ **Note:** The widget uses the **undocumented** `https://ollama.com/api/usage` endpoint. It may change or become gated at any time. If it breaks, please open an issue.

## Install

### From source

```bash
git clone https://github.com/AsharFatmi/ollama-usage-widget.git
cd ollama-usage-widget
./scripts/install.sh
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
launchctl bootout gui/$(id -u)/com.asharfatmi.ollama-usage-widget
rm -rf ~/Applications/ollama-usage-widget
rm ~/Library/LaunchAgents/com.asharfatmi.ollama-usage-widget.plist
```

## How it works

| Data | Source |
|------|--------|
| Weekly / session usage, per-model requests, cost | `GET https://ollama.com/api/usage` (Bearer token) |
| Local models + VRAM | `GET http://localhost:11434/api/ps` |
| 7-day activity history | locally accumulated daily deltas (the API exposes no history) |

The API key is never stored in the app bundle — it lives in your Keychain or env file only.

## License

[MIT](LICENSE) © 2026 Ashar Fatmi
