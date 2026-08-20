TITLE: My Ollama Cloud quota died mid-batch twice this month. Built a menu bar widget so it never surprises me again

BODY:

A lot of us are running local models plus Ollama Cloud on top. The annoying part is the cloud side: no native way to see usage, the settings page in the browser is a manual chore, and the only API is undocumented.

I got bitten twice in a month, walked back to a dead job both times. So I built a native macOS menu bar widget (Swift + AppKit, no Electron):

![The pill in the menu bar](https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/docs/pill.png)

- Pill in the menu bar: session % and weekly %, e.g. 4.6% · 23.7%
- Two hollow rings, weekly and the 5h session window, percentage inside
- Per-model request counts
- A 7-day activity chart of your usage
- A local Ollama section with loaded models and VRAM

Install:

```bash
curl -fsSL https://raw.githubusercontent.com/AsharFatmi/ollama-usage-widget/master/install.sh | bash
```

or via Homebrew:

```
brew tap asharfatmi/tap
brew install --cask ollama-usage-widget
```

or grab the DMG from https://github.com/AsharFatmi/ollama-usage-widget/releases

Key goes in the macOS Keychain, never plaintext.

The reason it's open source (MIT): it reads the undocumented /api/usage endpoint. If Ollama changes it, the fix is a small edit, not a dead app.

Before building I looked for existing tools: a GNOME extension for Linux and a couple of CLIs. Nothing native for macOS. So now there is one.

Happy to talk about the undocumented API, the Keychain handling, or the AppKit internals. Star if it saves you a dead batch job: https://github.com/AsharFatmi/ollama-usage-widget
