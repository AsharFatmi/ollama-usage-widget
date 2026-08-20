TITLE: My Ollama quota died with no warning twice this month. So I built a menu bar widget for it

BODY:

I use Ollama Cloud a lot, and twice this month a job failed halfway with a quota error while I was away from the keyboard. The annoying part: there's no way to see your usage without logging into the settings page. No Mac app, no menu bar widget, nothing native.

So I built one. It's a small Swift/AppKit menu bar app (no Electron) that shows:

![The menu bar pill](https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/pill.png)

- A pill with your session % and weekly %: 4.6% · 23.7%, always visible
- Two rings for Weekly and Session (5h), percentage inside, color shifts as you climb
- Per-model request counts, so you can finally see which model eats your quota
- A 7-day activity chart of your usage
- Local Ollama state too: loaded models and VRAM

Install (Apple Silicon):

```
curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash
```

or via Homebrew:

```
brew tap asharfatmi/tap
brew install --cask ollama-usage-widget
```

or grab the DMG from https://github.com/AsharFatmi/ollama-usage-widget/releases

Then click the pill → Set Key and paste your Ollama Cloud API key. It goes in the macOS Keychain, not in plain text.

One thing to know: it uses the undocumented /api/usage endpoint, so Ollama could break it. That's why the whole thing is open source (MIT). If it breaks, the fix is a small change, and if you're a Swift dev, the code is easy to read.

Star if this saves you a surprise quota death: https://github.com/AsharFatmi/ollama-usage-widget
