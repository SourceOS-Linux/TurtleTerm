Name:           turtleterm
Version:        1.4.0
Release:        1%{?dist}
Summary:        AI agent terminal fabric for SourceOS

License:        MIT
URL:            https://github.com/SourceOS-Linux/TurtleTerm
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  rust cargo cmake pkg-config
BuildRequires:  fontconfig-devel freetype-devel openssl-devel
BuildRequires:  libX11-devel libxcb-devel libxkbcommon-devel zlib-devel
Requires:       python3 >= 3.10
Recommends:     git

%description
TurtleTerm is a WezTerm-based terminal emulator with a full AI agent fabric.

Includes 38+ commands: turtle-agentd (190+ actions), turtle-copilot (self-hosted
AI with Claude/Ollama/Noetica backends), turtle-gh (gh CLI parity with Gitea),
turtle-env (project env management), turtle-diagnose (health checks),
turtle-chain (agent pipelines), turtle-apply (AI patch application), and more.

Shell integration for zsh, bash, fish, and PowerShell. MCP server for
Claude Code integration. SynapseIQ LSP support.

%prep
%autosetup

%build
cargo build --release --locked -p wezterm -p wezterm-gui -p wezterm-mux-server

%install
TURTLE_TERM_STAGE_PREFIX=%{buildroot}%{_prefix} bash packaging/scripts/stage-linux-package.sh

# WezTerm binaries
install -d %{buildroot}%{_libexecdir}/turtleterm
install -m 0755 target/release/wezterm            %{buildroot}%{_libexecdir}/turtleterm/
install -m 0755 target/release/wezterm-gui         %{buildroot}%{_libexecdir}/turtleterm/
install -m 0755 target/release/wezterm-mux-server  %{buildroot}%{_libexecdir}/turtleterm/

# turtleterm wrapper scripts
install -d %{buildroot}%{_libexecdir}/turtleterm-bin
install -m 0755 assets/sourceos/bin/turtleterm          %{buildroot}%{_libexecdir}/turtleterm-bin/
install -m 0755 assets/sourceos/bin/turtleterm-mux-server %{buildroot}%{_libexecdir}/turtleterm-bin/

# Shell wrapper shims for turtleterm / turtleterm-mux-server
install -d %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/turtleterm << 'EOF'
#!/bin/sh
export TURTLE_TERM_RUNTIME_DIR="%{_libexecdir}/turtleterm"
export TURTLETERM_CONFIG="%{_sysconfdir}/turtleterm/turtleterm.lua"
exec "%{_libexecdir}/turtleterm-bin/turtleterm" "$@"
EOF
chmod 0755 %{buildroot}%{_bindir}/turtleterm

cat > %{buildroot}%{_bindir}/turtleterm-mux-server << 'EOF'
#!/bin/sh
export TURTLE_TERM_RUNTIME_DIR="%{_libexecdir}/turtleterm"
exec "%{_libexecdir}/turtleterm-bin/turtleterm-mux-server" "$@"
EOF
chmod 0755 %{buildroot}%{_bindir}/turtleterm-mux-server

# Agent scripts
for script in \
  sourceos-term turtle-term turtle-agentd turtle-agentctl turtle-agent-status \
  turtle-tmux turtle-cloudfog turtle-superconscious turtle-agent-machine \
  turtle-language turtle-session turtle-synapseiq synapseiq-lsp \
  turtle-plan-view turtle-selftest turtle-runbook turtle-voice turtle-sync \
  turtle-perf turtle-persona turtle-files turtle-bg turtle-dash turtle-pr \
  turtle-issue turtle-hooks turtle-gitea turtle-ci turtle-review turtle-watch \
  turtle-cost turtle-copilot turtle-gh turtle-env turtle-diagnose \
  turtle-apply turtle-chain turtle-ai-chat; do
    src="assets/sourceos/bin/${script}"
    if [ -f "${src}" ]; then
        install -m 0755 "${src}" %{buildroot}%{_bindir}/
    fi
done

# MCP server
if [ -f "assets/sourceos/mcp/turtle-mcp-server" ]; then
    install -d %{buildroot}%{_datadir}/turtleterm/mcp
    install -m 0755 assets/sourceos/mcp/turtle-mcp-server \
        %{buildroot}%{_datadir}/turtleterm/mcp/
    ln -s %{_datadir}/turtleterm/mcp/turtle-mcp-server \
        %{buildroot}%{_bindir}/turtle-mcp-server
fi

# Shell integration
install -d %{buildroot}%{_datadir}/turtleterm/shell
for f in \
  turtle-shell-init.zsh turtle-shell-init.bash turtle-shell-init.fish \
  turtle-shell-init.ps1 \
  turtle-agentctl-completions.zsh turtle-agentctl-completions.bash \
  turtle-agentctl-completions.fish turtle-agentctl-completions.ps1 \
  turtle-gh-completions.zsh turtle-gh-completions.bash \
  turtle-copilot-completions.zsh turtle-copilot-completions.bash; do
    if [ -f "assets/sourceos/shell/${f}" ]; then
        install -m 0644 "assets/sourceos/shell/${f}" \
            %{buildroot}%{_datadir}/turtleterm/shell/
    fi
done

# Config
install -d %{buildroot}%{_sysconfdir}/turtleterm
if [ -f "assets/sourceos/turtleterm.lua" ]; then
    install -m 0644 assets/sourceos/turtleterm.lua \
        %{buildroot}%{_sysconfdir}/turtleterm/turtleterm.lua
fi

# Desktop integration
if [ -f "assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop" ]; then
    install -d %{buildroot}%{_datadir}/applications
    install -m 0644 assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop \
        %{buildroot}%{_datadir}/applications/
fi
if [ -f "assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml" ]; then
    install -d %{buildroot}%{_datadir}/metainfo
    install -m 0644 assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml \
        %{buildroot}%{_datadir}/metainfo/
fi
if [ -f "assets/sourceos/brand/ai.sourceos.TurtleTerm.svg" ]; then
    install -d %{buildroot}%{_datadir}/icons/hicolor/scalable/apps
    install -m 0644 assets/sourceos/brand/ai.sourceos.TurtleTerm.svg \
        %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/
fi

%post
# Update desktop/icon caches
update-desktop-database -q %{_datadir}/applications/ 2>/dev/null || :
gtk-update-icon-cache -q -t %{_datadir}/icons/hicolor/ 2>/dev/null || :

# MCP server convenience link
ln -sf %{_datadir}/turtleterm/mcp/turtle-mcp-server \
    /usr/local/bin/turtle-mcp-server 2>/dev/null || :

%preun
if [ $1 -eq 0 ]; then
    # Final removal — clean up the /usr/local/bin symlink
    rm -f /usr/local/bin/turtle-mcp-server
fi

%postun
if [ $1 -eq 0 ]; then
    update-desktop-database -q %{_datadir}/applications/ 2>/dev/null || :
    gtk-update-icon-cache -q -t %{_datadir}/icons/hicolor/ 2>/dev/null || :
fi

%files
%license LICENSE
%doc README.md
%{_bindir}/turtleterm
%{_bindir}/turtleterm-mux-server
%{_libexecdir}/turtleterm/
%{_libexecdir}/turtleterm-bin/
%config(noreplace) %{_sysconfdir}/turtleterm/
%{_datadir}/turtleterm/
%optional %{_datadir}/applications/ai.sourceos.TurtleTerm.desktop
%optional %{_datadir}/metainfo/ai.sourceos.TurtleTerm.metainfo.xml
%optional %{_datadir}/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg

# Dynamic agent scripts — list each explicitly that is installed
%ghost %{_bindir}/sourceos-term
%ghost %{_bindir}/turtle-term
%ghost %{_bindir}/turtle-agentd
%ghost %{_bindir}/turtle-agentctl
%ghost %{_bindir}/turtle-copilot
%ghost %{_bindir}/turtle-gh
%ghost %{_bindir}/turtle-env
%ghost %{_bindir}/turtle-diagnose
%ghost %{_bindir}/turtle-apply
%ghost %{_bindir}/turtle-chain
%ghost %{_bindir}/turtle-selftest
%ghost %{_bindir}/turtle-mcp-server

%changelog
* Sat Jun 21 2026 SourceOS Linux <maintainers@sourceos.ai> - 1.4.0-1
- v1.4.0: self-hosted co-pilot (Claude/Ollama/Noetica), gh CLI parity via turtle-gh,
  workspace intelligence, env management, health diagnostics, AI patch application,
  agent pipelines, WezTerm Lua copilot surface (CMD+SHIFT+K/J/D/W)

* Mon Jan 01 2024 SourceOS Linux <maintainers@sourceos.ai> - 1.0.0-1
- Initial RPM package
