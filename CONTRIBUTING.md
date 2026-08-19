# Contributing

Thanks for wanting to contribute to the Ollama Usage Widget! 🦙

## Development setup

```bash
git clone https://github.com/AsharFatmi/ollama-usage-widget.git
cd ollama-usage-widget
swift build
swift test
```

> **Toolchain note:** if `swift build` fails at the manifest/linker stage, your Command Line Tools SwiftPM library is likely stale — install Swift via Homebrew (`brew install swift`) and make sure `/opt/homebrew/bin` is before `/usr/bin` in `PATH`.

## Workflow

1. Fork the repo and create a branch off `master`
2. Write tests for new behavior (Swift Testing framework — see `Tests/`)
3. Run `swift test` — the suite must stay green
4. Open a PR with a clear description

## Code style

- Swift 6, AppKit, SwiftPM (no Xcode project files)
- Target macOS 14+
- Keep the popover self-contained: view creation belongs in `loadView` or `reloadData`, never in data-fetching code
- Don't hardcode user-specific paths — see `EnvFileReader` for the key-resolution chain

## Reporting bugs

Open an issue with:

- macOS version + architecture
- Ollama version (`ollama --version`) and whether Cloud usage is enabled
- A screenshot of the popover if it's a UI issue
- Console output if the app crashes

## Questions

Open a discussion or an issue — no question is too small.
