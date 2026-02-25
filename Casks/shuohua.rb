cask "shuohua" do
  version "0.1.0"
  sha256 "7fe12703c21a2532b71ba74d73f6dc2b1080c29450afd9e7b27208e5e7a50a02"

  url "https://github.com/T1mn/shuohua/releases/download/v#{version}/shuohua-#{version}.dmg"
  name "Shuohua"
  name "说话"
  desc "Offline voice-to-text for macOS, powered by on-device AI"
  homepage "https://github.com/T1mn/shuohua"

  depends_on macos: ">= :sonoma"
  depends_on arch: :arm64

  app "说话.app"
end
