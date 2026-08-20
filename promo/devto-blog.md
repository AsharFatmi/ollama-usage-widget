---
title: "Twice my Ollama quota died with no warning. So I built a menu bar widget"
description: "Ollama Cloud has no dashboard you can pin and no Mac app. After burning through my weekly quota twice with zero heads-up, I built a native menu bar widget. One-line install, open source."
published: false
tags: [macos, ollama, llm, opensource, swift]
canonical_url: https://dev.to/kingashar10/i-built-a-menu-bar-widget-for-ollama-cloud-usage-3k9b
cover_image: https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/popover.png
---

# Twice my Ollama quota died with no warning. So I built a menu bar widget

Twice last month a job of mine just died mid-run. I walked away to let it work, came back expecting results, and found an error about the quota instead. Then came the worst part: trying to figure out how I had burned through a week of usage. The browser settings page showed a number. That's it. No breakdown. No graph. No hint of which model did it or when it happened. Just a number I was already over.

That sinking feeling is the whole reason this widget exists.

Ollama Cloud has no Mac app for your usage. No dashboard you can pin, no menu bar widget, no tray icon. The only options are the settings page in the browser, which you have to remember to log in and check, and an undocumented API endpoint that most people don't even know about. I watch my disk space, my network, my battery, my iStat stuff. But the one thing that can stop my work cold is the one thing I can't see. That's backwards.

So I built something.

Ollama Usage Widget is a native macOS menu bar app. Swift and AppKit, no Electron, no webview, no extra runtime. Just a small pill at the top of your screen that tells you the truth.

[![GitHub](https://img.shields.io/badge/GitHub-AsharFatmi%2Follama--usage--widget-181717?style=flat&logo=github&logoColor=white)](https://github.com/AsharFatmi/ollama-usage-widget)

![The menu bar pill: a black capsule showing the llama icon and session and weekly usage percentages](https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/pill.png)

What it does:

- A pill in the menu bar with your session usage first and your weekly usage second, like `4.6% · 23.7%`. You know where you stand without clicking anything.
- Click it and you get two hollow rings, one for the week, one for the 5-hour session window. The percentage sits inside the ring, and the color shifts as you climb.
- A per-model breakdown, so you can finally see which model eats the most.
- A 7-day activity chart built from your real usage, which shows its shape after a few days.
- A local Ollama section with your loaded models and VRAM, for when you also run Ollama on the machine.
- Your API key lives in the macOS Keychain. Nothing is ever written to disk in plain text, and the app only talks to Ollama's own servers.

![The popover: weekly and session rings, a per-model breakdown, and a 7-day activity chart](https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/popover.png)

## How it works

The widget polls Ollama's usage endpoint (yes, the undocumented one) with your key, and reads local state from your running Ollama instance. Every positive change gets recorded, and that history is what feeds the 7-day chart.

I want to be straight about one thing: that endpoint is undocumented. Ollama could change it or lock it down any time. That's exactly why this is open source. If the API shifts, this is a quick fix, not a dead app. The codebase is small, MIT licensed, and easy to read.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash
```

That downloads the latest release, puts the app in `/Applications`, and starts up a launch agent so it starts when you log in and stays alive. Because the file comes via curl, there's no quarantine flag and no Gatekeeper nagging.

Prefer Homebrew? That works too:

```bash
brew tap asharfatmi/tap
brew install --cask ollama-usage-widget
```

Prefer manual? The DMG is on the [releases page](https://github.com/AsharFatmi/ollama-usage-widget/releases). After that, click the pill, pick Set Key…, paste your Ollama Cloud API key, and you're done.

## Why I think you'll like it

Because it ends the surprise. The pill is always there. You'll see 91% weekly usage before you start a huge batch job, not after it fails.

It's free, it's MIT, it's a native app, and it's small. Not another Electron process sitting in your menu bar.

## Nobody else built this

I looked before building. The closest things are a GNOME extension for Linux and a couple of Python CLI tools. There was no native macOS menu bar widget for Ollama Cloud usage. For a platform this popular, that gap felt silly. So now there is one.

## Next up

Notarized builds and auto-updates are on the list, which means an Apple developer certificate. If this widget saves you one quota surprise, a star on GitHub gets me a lot closer to that.

[github.com/AsharFatmi/ollama-usage-widget](https://github.com/AsharFatmi/ollama-usage-widget) · MIT · Apple Silicon
