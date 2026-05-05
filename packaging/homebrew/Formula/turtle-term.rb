# frozen_string_literal: true

class TurtleTerm < Formula
  desc "TurtleTerm: SourceOS policy-aware agent terminal fabric"
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

    (libexec/"turtle-term").install "target/release/wezterm"
    (libexec/"turtle-term").install "target/release/wezterm-gui"
    (libexec/"turtle-term").install "target/release/wezterm-mux-server"

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

    libexec.install "assets/sourceos/bin/turtleterm" => "turtleterm"
    libexec.install "assets/sourceos/bin/turtleterm-mux-server" => "turtleterm-mux-server"
    chmod 0755, libexec/"turtleterm"
    chmod 0755, libexec/"turtleterm-mux-server"

    (bin/"turtleterm").write <<~EOS
      #!/bin/sh
      export TURTLE_TERM_RUNTIME_DIR="#{libexec}/turtle-term"
      export TURTLETERM_CONFIG="#{etc}/turtle-term/turtleterm.lua"
      exec "#{libexec}/turtleterm" "$@"
    EOS
    (bin/"turtleterm-mux-server").write <<~EOS
      #!/bin/sh
      export TURTLE_TERM_RUNTIME_DIR="#{libexec}/turtle-term"
      exec "#{libexec}/turtleterm-mux-server" "$@"
    EOS

    profile_source = if File.exist?("assets/sourceos/turtleterm.lua")
      Pathname("assets/sourceos/turtleterm.lua")
    elsif File.exist?("assets/sourceos/wezterm.lua")
      Pathname("assets/sourceos/wezterm.lua")
    else
      profile = buildpath/"turtleterm.lua"
      profile.write <<~LUA
        local wezterm = require 'wezterm'
        local config = wezterm.config_builder()
        config.set_environment_variables = {
          SOURCEOS_TERMINAL_FRONTEND = 'turtle-term',
          SOURCEOS_TERMINAL_PROFILE = 'turtleterm-homebrew-fallback',
          TURTLETERM_PROFILE = 'turtleterm-homebrew-fallback',
        }
        return config
      LUA
      profile
    end
    etc.install profile_source => "turtle-term/turtleterm.lua"
    pkgshare.install "docs/sourceos"
    pkgshare.install "assets/sourceos/skills" => "skills" if Dir.exist?("assets/sourceos/skills")
    pkgshare.install "assets/sourceos/brand" => "brand" if Dir.exist?("assets/sourceos/brand")
    pkgshare.install "assets/sourceos/desktop" => "desktop" if Dir.exist?("assets/sourceos/desktop")

    if OS.linux?
      (share/"applications").install "assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop" if File.exist?("assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop")
      (share/"metainfo").install "assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml" if File.exist?("assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml")
      (share/"icons/hicolor/scalable/apps").install "assets/sourceos/brand/ai.sourceos.TurtleTerm.svg" if File.exist?("assets/sourceos/brand/ai.sourceos.TurtleTerm.svg")
    end
  end

  def caveats
    <<~EOS
      TurtleTerm installed its profile at:
        #{etc}/turtle-term/turtleterm.lua

      To use it as your terminal profile:
        ln -sf #{etc}/turtle-term/turtleterm.lua ~/.wezterm.lua

      To launch TurtleTerm:
        turtleterm

      To test TurtleTerm:
        turtle-term paths
        turtle-term run -- echo hello
        turtle-agentctl --stdio ping
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
