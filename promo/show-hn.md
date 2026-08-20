Show HN: My menu bar widget for Ollama Cloud usage, because finding out your quota is dead by hitting an error is miserable

Twice last month my Ollama Cloud quota ran out mid-job. No warning, no dashboard pinned anywhere, just an error after hours of compute. The settings page in the browser shows a number. That's the whole native experience.

So I built a small native macOS menu bar app (Swift + AppKit, no Electron) that keeps the numbers in front of me:

![The pill in the menu bar: session % and weekly % at a glance](https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/pill.png)

- Pill in the menu bar: session % first, weekly % second, e.g. 4.6% · 23.7%
- Click it for two hollow rings (weekly + 5h session window), percentage inside, color shifts as you climb
- Per-model request counts, so I can see which model eats the quota
- A 7-day activity chart built from my own usage history
- Local Ollama state: loaded models and VRAM
- API key stored in the macOS Keychain

Install:

    curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash

Or grab the DMG from the releases page: https://github.com/AsharFatmi/ollama-usage-widget/releases

Set your key via the pill → Set Key… and that's it.

The honest caveat: it uses Ollama's undocumented /api/usage endpoint. It could break whenever they change something. I open-sourced it (MIT) so that when that day comes, it's a 10-minute fix instead of a dead app.

Apple Silicon only for now. Happy to talk about the undocumented API, the Keychain handling, or the AppKit side. What would you want to see next?
