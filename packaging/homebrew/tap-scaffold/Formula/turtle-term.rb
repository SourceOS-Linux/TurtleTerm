# frozen_string_literal: true

# Stable release formula for SourceOS-Linux/homebrew-tap.
# HEAD install uses the live main branch formula at:
#   packaging/homebrew/Formula/turtle-term.rb
#
# FIXME: Update url, sha256, and version after cutting turtle-term-v0.1.0.
class TurtleTerm < Formula
  desc "SourceOS policy-aware agent terminal fabric"
  homepage "https://github.com/SourceOS-Linux/TurtleTerm"
  license "MIT"

  # FIXME: Replace with real release tarball URL and sha256 after v0.1.0 is cut.
  url "https://github.com/SourceOS-Linux/TurtleTerm/archive/refs/tags/turtle-term-v0.1.0.tar.gz"
  sha256 "FIXME_replace_with_real_sha256_after_release"
  version "0.1.0"

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

    # Python layer: gateway, CLI tools, MCP server.
    (etc/"turtle-term").install "assets/sourceos/turtleterm.lua"
    (pkgshare/"turtle-term").install "assets/sourceos"
    python_bin = pkgshare/"turtle-term/sourceos/bin"
    mcp_bin = pkgshare/"turtle-term/sourceos/mcp"

    %w[
      turtleterm turtleterm-mux-server
      turtle-term sourceos-term
      turtle-agentd turtle-agentctl turtle-agentd
      turtle-tmux turtle-cloudfog turtle-superconscious
      turtle-agent-machine turtle-language turtle-session
      turtle-agent-status
    ].each do |script|
      src = python_bin/script
      next unless src.exist?
      (bin/script).write_env_script src, PYTHONPATH: python_bin
    end

    (bin/"turtle-mcp-server").write_env_script mcp_bin/"turtle-mcp-server", PYTHONPATH: python_bin

    %w[turtleterm turtle-term sourceos-term].each do |launcher|
      (bin/launcher).write <<~SH
        #!/bin/sh
        exec "#{libexec}/turtle-term/wezterm-gui" --config-file "#{etc}/turtle-term/turtleterm.lua" "$@"
      SH
      chmod 0755, bin/launcher
    end
  end

  def caveats
    <<~EOS
      TurtleTerm profile installed at:
        #{etc}/turtle-term/turtleterm.lua

      Launch:
        turtleterm

      Verify:
        turtle-term paths
        turtle-agentctl --stdio ping
        turtle-mcp-server  (exposes MCP tools to Claude Code and other clients)

      Shell integration (add to ~/.zshrc or ~/.bashrc):
        source #{pkgshare}/turtle-term/sourceos/shell/turtle-shell-init.zsh
        source #{pkgshare}/turtle-term/sourceos/shell/turtle-shell-init.bash

      Claude Code MCP wiring (add to ~/.claude/settings.json):
        {
          "mcpServers": {
            "turtleterm": {
              "type": "stdio",
              "command": "#{bin}/turtle-mcp-server"
            }
          }
        }
    EOS
  end

  test do
    ENV["SOURCEOS_TERMINAL_SESSION_ID"] = "turtle-term-brew-test"
    ENV["SOURCEOS_WORKSPACE"] = "turtle-term-brew"
    ENV["SOURCEOS_TERMINAL_EVENTS"] = (testpath/"events.ndjson").to_s
    ENV["SOURCEOS_TERMINAL_RECEIPTS"] = (testpath/"receipts").to_s

    assert_match "turtle-agentd", shell_output("#{bin}/turtle-agentctl --stdio ping")
    assert_match "surfaces", shell_output("#{bin}/turtle-agentctl --stdio surfaces")
  end
end
