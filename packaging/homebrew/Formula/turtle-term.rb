# frozen_string_literal: true

class TurtleTerm < Formula
  desc "TurtleTerm: SourceOS policy-aware agent terminal fabric based on WezTerm"
  homepage "https://github.com/SourceOS-Linux/TurtleTerm"
  license "MIT"
  head "https://github.com/SourceOS-Linux/TurtleTerm.git", branch: "main"

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

    turtle_scripts = %w[
      sourceos-term
      turtle-term
      turtle-agentd
      turtle-agentctl
      turtle-tmux
    ]
    turtle_scripts.each do |script|
      chmod 0755, "assets/sourceos/bin/#{script}"
      bin.install "assets/sourceos/bin/#{script}"
    end

    etc.install "assets/sourceos/wezterm.lua" => "turtle-term/wezterm.lua"
    pkgshare.install "docs/sourceos"
    pkgshare.install "assets/sourceos/skills" => "skills"
  end

  def caveats
    <<~EOS
      TurtleTerm installed the SourceOS WezTerm profile at:
        #{etc}/turtle-term/wezterm.lua

      To use it as your WezTerm config:
        ln -sf #{etc}/turtle-term/wezterm.lua ~/.wezterm.lua

      To test TurtleTerm:
        turtle-term paths
        turtle-term run -- echo hello
        turtle-agentctl --stdio ping

      `sourceos-term` is installed as a compatibility command.
      This formula is experimental and currently intended for --HEAD installs.
    EOS
  end

  test do
    assert_match "TurtleTerm command wrapper", shell_output("#{bin}/sourceos-term --help")
    assert_match "TurtleTerm command wrapper", shell_output("#{bin}/turtle-term --help")
    assert_match "TurtleTerm local agent gateway", shell_output("#{bin}/turtle-agentd --help")
    assert_match "TurtleTerm agent gateway CLI", shell_output("#{bin}/turtle-agentctl --help")
    assert_match "TurtleTerm tmux bridge", shell_output("#{bin}/turtle-tmux --help")

    events = testpath/"events.ndjson"
    receipts = testpath/"receipts"
    ENV["SOURCEOS_TERMINAL_SESSION_ID"] = "turtle-term-brew-test"
    ENV["SOURCEOS_WORKSPACE"] = "turtle-term-brew"
    ENV["SOURCEOS_TERMINAL_EVENTS"] = events.to_s
    ENV["SOURCEOS_TERMINAL_RECEIPTS"] = receipts.to_s
    ENV["SOURCEOS_ACTOR_ID"] = "test:homebrew"
    ENV["SOURCEOS_POLICY_BUNDLE_ID"] = "policy:homebrew-test"
    ENV["SOURCEOS_EXECUTION_DOMAIN"] = "host"

    assert_match "hello", shell_output("#{bin}/turtle-term run -- echo hello")
    assert_predicate events, :exist?
    assert_match "command.completed", events.read
    assert_match "turtle-agentd", shell_output("#{bin}/turtle-agentctl --stdio ping")
  end
end
