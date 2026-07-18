# frozen_string_literal: true

class TurtleTerm < Formula
  desc "SourceOS policy-aware agent terminal fabric"
  homepage "https://github.com/SourceOS-Linux/TurtleTerm"
  license "MIT"
  head "https://github.com/SourceOS-Linux/TurtleTerm.git", branch: "main"

  depends_on "pkg-config" => :build
  depends_on "rust" => :build

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
    depends_on "python@3.12"
    depends_on "wayland"
    depends_on "xcb-util"
    depends_on "xcb-util-image"
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
      turtle-agent-status
      turtle-tmux
      turtle-cloudfog
      turtle-superconscious
      turtle-agent-machine
      turtle-language
      turtle-session
    ]
    turtle_scripts.each do |script|
      script_path = "assets/sourceos/bin/#{script}"
      next unless File.exist?(script_path)

      chmod 0755, script_path
      bin.install script_path
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
    (etc/"turtle-term").mkpath
    (etc/"turtle-term/turtleterm.lua").write profile_source.read
    pkgshare.install "docs/sourceos"
    pkgshare.install "assets/sourceos/skills" => "skills" if Dir.exist?("assets/sourceos/skills")
    pkgshare.install "assets/sourceos/brand" => "brand" if Dir.exist?("assets/sourceos/brand")
    pkgshare.install "assets/sourceos/desktop" => "desktop" if Dir.exist?("assets/sourceos/desktop")
    pkgshare.install "assets/sourceos/shell" => "shell" if Dir.exist?("assets/sourceos/shell")
    if File.exist?("assets/sourceos/mcp/turtle-mcp-server")
      chmod 0755, "assets/sourceos/mcp/turtle-mcp-server"
      bin.install "assets/sourceos/mcp/turtle-mcp-server"
    end

    if OS.linux?
      if File.exist?("assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop")
        (share/"applications").install "assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop"
      end
      if File.exist?("assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml")
        (share/"metainfo").install "assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml"
      end
      if File.exist?("assets/sourceos/brand/ai.sourceos.TurtleTerm.svg")
        (share/"icons/hicolor/scalable/apps").install "assets/sourceos/brand/ai.sourceos.TurtleTerm.svg"
      end
    end
  end

  def caveats
    <<~EOS
      TurtleTerm v0.2 installed.

      Profile:      #{etc}/turtle-term/turtleterm.lua
      Shell inits:  #{pkgshare}/shell/
      MCP server:   #{bin}/turtle-mcp-server
      Skills:       #{pkgshare}/skills/

      Shell integration — add to your shell rc:
        source #{pkgshare}/shell/turtle-shell-init.zsh   # zsh
        source #{pkgshare}/shell/turtle-shell-init.bash  # bash
        source #{pkgshare}/shell/turtle-shell-init.fish  # fish (add to config.fish)

      Claude Code MCP — add to ~/.claude/settings.json:
        {
          "mcpServers": {
            "turtleterm": {
              "type": "stdio",
              "command": "#{bin}/turtle-mcp-server"
            }
          }
        }

      AI features — set ANTHROPIC_API_KEY for Claude-powered explain/NL→shell.
      Fallback: Noetica at SOURCEOS_NOETICA_URL (default http://localhost:8080).

      Keybinds (in TurtleTerm):
        CMD+↑ / CMD+↓       Jump between prompt marks
        CMD+B               Copy last command output to clipboard
        CMD+SHIFT+B         Copy last command to clipboard
        CTRL+SHIFT+E        Explain selected text (AI)
        CTRL+SHIFT+N        Natural language → shell command
        CTRL+SHIFT+A        Show Atlas context from .atlas/
        CTRL+SHIFT+G        Policy gate prompt

      Quick smoke test:
        turtle-agentctl --stdio ping
        turtle-agentctl --stdio noetica-status
        turtle-agentctl explain-selection "No such file or directory"
        turtle-agentctl nl-to-shell "show disk usage by directory"
    EOS
  end

  test do
    assert_match "TurtleTerm command wrapper", shell_output("#{bin}/turtle-term --help")
    assert_match "TurtleTerm local agent gateway", shell_output("#{bin}/turtle-agentd --help")
    assert_match "TurtleTerm agent gateway CLI", shell_output("#{bin}/turtle-agentctl --help")
    if (bin/"turtle-agent-status").exist?
      assert_match "SourceOS agent reliability artifacts", shell_output("#{bin}/turtle-agent-status --help")
    end
    assert_match "TurtleTerm tmux bridge", shell_output("#{bin}/turtle-tmux --help")

    events = testpath/"events.ndjson"
    receipts = testpath/"receipts"
    ENV["SOURCEOS_TERMINAL_SESSION_ID"] = "turtle-term-brew-test"
    ENV["SOURCEOS_WORKSPACE"] = "turtle-term-brew"
    ENV["SOURCEOS_TERMINAL_EVENTS"] = events.to_s
    ENV["SOURCEOS_TERMINAL_RECEIPTS"] = receipts.to_s
    ENV["SOURCEOS_EXECUTION_DOMAIN"] = "host"
    ENV["ANTHROPIC_API_KEY"] = ""

    assert_match "turtle-agentd", shell_output("#{bin}/turtle-agentctl --stdio ping")
    assert_match "surfaces", shell_output("#{bin}/turtle-agentctl --stdio surfaces")
    assert_match "explain_selection", shell_output("#{bin}/turtle-agentctl --stdio explain-selection 'test output'")
    assert_match "nl_to_shell", shell_output("#{bin}/turtle-agentctl --stdio nl-to-shell 'list files by size'")
    assert_match "atlas_context", shell_output("#{bin}/turtle-agentctl --stdio atlas-context #{testpath}")
    assert_match "diagnostics", shell_output("#{bin}/turtle-language diagnostics #{__FILE__}")
    assert_path_exists "#{pkgshare}/shell/turtle-shell-init.zsh"
    assert_path_exists "#{pkgshare}/shell/turtle-shell-init.bash"
    assert_path_exists "#{pkgshare}/shell/turtle-shell-init.fish"
    assert_path_exists "#{bin}/turtle-mcp-server"
  end
end
