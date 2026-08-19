# Security Policy

## Reporting a vulnerability

The Ollama Usage Widget is a local, open-source menu bar utility. If you find a security issue:

- **Do not open a public issue** for exploitable vulnerabilities.
- Email a detailed report to the maintainer via the GitHub security advisory flow: **https://github.com/AsharFatmi/ollama-usage-widget/security/advisories**

Please include:

- The affected version
- Steps to reproduce
- Impact assessment

## What this app handles

- **Ollama Cloud API key** — stored in the macOS Keychain (or an env file you control). It is sent only to `https://ollama.com` over TLS as a Bearer token.
- **Local usage data** — fetched from `http://localhost:11434` and kept on-device; nothing is transmitted except the API request above.

## Supported versions

Only the latest release on the `master` branch is supported. Report against the tip of `master`.
