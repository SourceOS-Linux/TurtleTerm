# frozen_string_literal: true

class SourceosWezterm < Formula
  desc "SourceOS Terminal Workbench: policy-aware agent terminal fabric based on WezTerm"
  homepage "https://github.com/SourceOS-Linux/wezterm"
  license "MIT"
  head "https://github.com/SourceOS-Linux/wezterm.git", branch: "main"

  depends_on "rust" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.12"

  on_macos do
    depends_on "cmake" => :build
  end

  on_linux do
    depends_on "cmake" => :build
    depends_on "fontconfig"
    depends_on "freetype"
    depends_on "libx11"
    depends_on "libxcb"
    depends_on "libxkbcommon"
    depends_on "openssl@3"
    depends_on "wayland"
    depends_on "zlib"
  end

  def install
    ENV["OPENSSL_NO_VENDOR"] = "1" if OS.linux?

    system "cargo", "build", "--release", "--locked", "-p", "wezterm"
    system "cargo", "build", "--release", "--locked", "-p", "wezterm-gui"
    system "cargo", "build", "--release", "--locked", "-p", "wezterm-mux-server"

    bin.install "target/release/wezterm"
    bin.install "target/release/wezterm-gui"
    bin.install "target/release/wezterm-mux-server"

    bin.install "assets/sourceos/bin/sourceos-term"
    etc.install "assets/sourceos/wezterm.lua" => "sourceos/wezterm/wezterm.lua"
    pkgshare.install "docs/sourceos"
  end

  def caveats
    <<~EOS
      SourceOS Terminal Workbench installed the SourceOS WezTerm profile at:
        #{etc}/sourceos/wezterm/wezterm.lua

      To use it as your WezTerm config:
        ln -sf #{etc}/sourceos/wezterm/wezterm.lua ~/.wezterm.lua

      To test the SourceOS command wrapper:
        sourceos-term paths
        sourceos-term run -- echo hello

      This formula is experimental and currently intended for --HEAD installs.
      Windows packaging is postponed; macOS and Linux Homebrew are the first lanes.
    EOS
  end

  test do
    assert_match "SourceOS terminal command wrapper", shell_output("#{bin}/sourceos-term --help")

    events = testpath/"events.ndjson"
    receipts = testpath/"receipts"

    ENV["SOURCEOS_TERMINAL_SESSION_ID"] = "sourceos-brew-test"
    ENV["SOURCEOS_WORKSPACE"] = "sourceos-brew"
    ENV["SOURCEOS_TERMINAL_EVENTS"] = events.to_s
    ENV["SOURCEOS_TERMINAL_RECEIPTS"] = receipts.to_s
    ENV["SOURCEOS_ACTOR_ID"] = "test:homebrew"
    ENV["SOURCEOS_POLICY_BUNDLE_ID"] = "policy:homebrew-test"
    ENV["SOURCEOS_EXECUTION_DOMAIN"] = "host"

    assert_match "hello", shell_output("#{bin}/sourceos-term run -- echo hello")
    assert_predicate events, :exist?
    assert_match "command.completed", events.read
  end
end
