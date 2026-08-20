TITLE: Menu bar widget for Ollama Cloud usage, native Swift, no Electron

BODY:

If you run Ollama Cloud on a Mac you already know the drill: the quota dies without warning and the only way to check is the browser settings page. There's no dashboard you can pin and no menu bar app. So I built one.

It's a real native app, Swift + AppKit, LSUIElement, sits in the menu bar with a tiny footprint. No Electron, no webview, no runtime.

What you get:

![The pill in the menu bar](https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/pill.png)

- A pill showing session % and weekly % (4.6% · 23.7%) without clicking anything
- Click it for two hollow rings with the percentage inside, colored by severity
- Per-model request counts, so you can see which model eats your quota
- A 7-day activity chart of your usage
- Local Ollama status: loaded models and VRAM
- API key stored in the macOS Keychain, never plaintext

Install (10 seconds):

```bash
curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash
```

Or via Homebrew:

```bash
brew tap asharfatmi/tap
brew install --cask ollama-usage-widget
```

Or grab the DMG from the releases page: https://github.com/AsharFatmi/ollama-usage-widget/releases

The story: I burned through my weekly quota twice last month and only found out when a job failed mid-run. A tiny always-visible pill fixes that whole class of problem.

Screenshot: https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/popover.png

I checked before building, there was no native macOS option for this, just a GNOME extension and some CLIs. So I made one. Open source, MIT, Apple Silicon for now. Feedback and feature ideas welcome (auto-update and notarization are next on the list).
