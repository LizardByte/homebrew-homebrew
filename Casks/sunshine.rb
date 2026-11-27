cask "sunshine" do
  arch arm: "arm64", intel: "x86_64"

  version "2026.9"
  sha256 arm:   "c011f017b300100f5c51de67abb8380f49484b9d936fb33e714881722ee267ce",
         intel: "e344bd61727768e1abec2fc4c8035ed843c914bf6ad15d18bb720c75c87cd1d2"

  url "https://github.com/LizardByte/Sunshine/releases/download/v#{version}/Sunshine-macOS-#{arch}.dmg"
  name "Sunshine"
  desc "Self-hosted game stream host for Moonlight"
  homepage "https://app.lizardbyte.dev/Sunshine"

  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  conflicts_with cask: "sunshine-beta"
  depends_on macos: :sonoma

  app "Sunshine.app"

  uninstall quit: "dev.lizardbyte.app.Sunshine"

  zap trash: [
    "~/.config/sunshine",
    "~/Library/Preferences/dev.lizardbyte.app.Sunshine.plist",
    "~/Library/Saved Application State/dev.lizardbyte.app.Sunshine.savedState",
  ]

  caveats <<~EOS
    #{token} uses the same configuration directory (~/.config/sunshine) as the
    lizardbyte/homebrew/sunshine formula. Do not run both at the same time.

    Grant Sunshine access in System Settings > Privacy & Security > Screen Recording
    (and Microphone, if streaming audio) the first time it is launched.
  EOS
end
