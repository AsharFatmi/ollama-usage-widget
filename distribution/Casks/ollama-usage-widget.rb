cask "ollama-usage-widget" do
  version "1.0.1"
  sha256 "fd701ee537e284318ed7f9dc5d0d76fba2ec40437a7ffe4462271516858a65c7"

  url "https://github.com/AsharFatmi/ollama-usage-widget/releases/download/v#{version}/OllamaUsageWidget-#{version}.dmg"
  name "Ollama Usage Widget"
  desc "Track Ollama Cloud usage and local Ollama state from the menu bar"
  homepage "https://github.com/AsharFatmi/ollama-usage-widget"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "OllamaUsageWidget.app"

  uninstall quit: "com.asharfatmi.ollama-usage-widget"

  zap trash: [
    "~/.ollama-usage-widget",
    "~/.ollama-usage-widget.env",
    "~/Library/LaunchAgents/com.asharfatmi.ollama-usage-widget.plist",
    "~/Library/Preferences/com.asharfatmi.ollama-usage-widget.plist",
    "~/Library/Preferences/OllamaUsageWidget.plist",
  ]
end
