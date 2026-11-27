cask "sunshine-beta" do
  arch arm: "arm64", intel: "x86_64"

  version "2026.1"
  sha256 arm:   "341af3294d656e3b045ec740e51d67682dec8f5af032e400c8fd2287feb75445",
         intel: "9cc3c46a6fbb33878b30a1bf64c92b21c9704e6378e90e7552b5d4ecdfd9ad4c"

  url "https://github.com/LizardByte/Sunshine/releases/download/v#{version}/Sunshine-macOS-#{arch}.dmg"
  name "Sunshine"
  desc "Self-hosted game stream host for Moonlight"
  homepage "https://app.lizardbyte.dev/Sunshine"

  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"]

        match = release["tag_name"]&.match(regex)
        next if match.blank?

        match[1]
      end
    end
  end

  conflicts_with cask: "sunshine"
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
