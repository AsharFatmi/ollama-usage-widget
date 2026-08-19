## Description

Adds the Ollama Usage Widget — a native macOS menu bar utility for tracking Ollama Cloud usage (weekly/session quotas, per-model request counts, cost) and local Ollama server state.

- Homepage: https://github.com/AsharFatmi/ollama-usage-widget
- Release: https://github.com/AsharFatmi/ollama-usage-widget/releases/tag/v1.0.0
- DMG: https://github.com/AsharFatmi/ollama-usage-widget/releases/download/v1.0.0/OllamaUsageWidget-1.0.0.dmg
- ARM64 only (Apple Silicon); cask token: `ollama-usage-widget`

-----

<!-- Do not tick a checkbox if you haven’t performed its action. Honesty is indispensable for a smooth review process. -->
<!-- Use [x] to mark item done before creation, or just click the checkboxes with device pointer after creation -->
<!-- In the following questions `<cask>` is the token of the cask you're editing. -->

After making any changes to a cask, existing or new, verify:

- [x] The submission is for [a stable version](https://docs.brew.sh/Acceptable-Casks#stable-versions) or [documented exception](https://docs.brew.sh/Acceptable-Casks#but-there-is-no-stable-version).
- [x] `brew audit --cask --online <cask>` is error-free.
- [x] `brew style --fix <cask>` reports no offenses.

Additionally, if adding a new cask:

- [x] Named the cask according to the [token reference](https://docs.brew.sh/Cask-Cookbook#token-reference).
- [x] Checked the cask was not [already refused](https://github.com/search?q=repo%3AHomebrew%2Fhomebrew-cask+is%3Aclosed+is%3Aunmerged+&type=pullrequests) (add your cask's name to the end of the search field).
- [x] `brew audit --cask --new <cask>` worked successfully.
- [x] `HOMEBREW_NO_INSTALL_FROM_API=1 brew install --cask <cask>` worked successfully.
- [x] `brew uninstall --cask <cask>` worked successfully.

-----

- [x] I did not use AI/LLM to create this PR, or I disclosed the tool/model below and reviewed its output, including [`zap` stanza](https://docs.brew.sh/Cask-Cookbook#stanza-zap) paths; I did not attribute commits to AI and will answer maintainer questions and review comments myself without AI/LLM.

<!-- If AI was used, explain below how it was used and how you verified the changes. Non-maintainers may only have one AI-assisted PR open at a time. See https://docs.brew.sh/Responsible-AI-Usage for guidance. -->

This cask was drafted with the assistance of an AI agent (Hermes, by Nous Research). I reviewed the cask and the `zap` trash paths against the app's real data locations (Keychain service `com.asharfatmi.ollama-usage-widget`, LaunchAgent plist, env-file fallbacks), verified the DMG SHA-256 locally, and ran `brew audit --cask --online`, `brew style --fix`, install, and uninstall against the cask in my personal tap. I will answer maintainer questions myself.

-----
