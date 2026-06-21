# TurtleTerm + BearBrowser + Noetica — Cross-Platform Install Matrix

| Product | macOS | Windows | Linux |
|---|---|---|---|
| **TurtleTerm** | `brew install sourceos-linux/tap/turtleterm` | `choco install turtleterm` | `brew install sourceos-linux/tap/turtleterm` or `.deb`/`.rpm` |
| **BearBrowser** | `brew install --cask sourceos-linux/tap/bearbrowser` | `choco install bearbrowser` | `brew install --cask sourceos-linux/tap/bearbrowser` or AppImage |
| **Noetica** | `brew install --cask sourceos-linux/tap/noetica` | `choco install noetica` | `brew install --cask sourceos-linux/tap/noetica` or systemd service |

## macOS — Homebrew

```bash
brew tap sourceos-linux/tap
brew install turtleterm                       # terminal + agent scripts
brew install --cask bearbrowser               # privacy browser
brew install --cask noetica                   # AI backend service
```

Shell integration:
```bash
echo 'source "$(brew --prefix)/share/turtleterm/shell/turtle-shell-init.zsh"' >> ~/.zshrc
```

## Windows — Chocolatey

```powershell
choco install turtleterm bearbrowser noetica
```

Shell integration (add to `$PROFILE`):
```powershell
. "$env:ProgramFiles\TurtleTerm\turtle-agent\shell\turtle-shell-init.ps1"
```

## Linux — Homebrew (Linuxbrew) or native packages

```bash
# Linuxbrew
brew tap sourceos-linux/tap
brew install turtleterm

# Debian/Ubuntu
wget https://github.com/SourceOS-Linux/TurtleTerm/releases/latest/download/turtleterm_amd64.deb
sudo dpkg -i turtleterm_amd64.deb

# RPM (Fedora/CentOS)
sudo rpm -i https://github.com/SourceOS-Linux/TurtleTerm/releases/latest/download/turtleterm_x86_64.rpm
```

Shell integration:
```bash
echo 'source /usr/share/turtleterm/shell/turtle-shell-init.bash' >> ~/.bashrc
# or for zsh:
echo 'source /usr/share/turtleterm/shell/turtle-shell-init.zsh' >> ~/.zshrc
```

## Post-install — All platforms

```
# Start self-hosted co-pilot
turtle-copilot start

# Point co-pilot at local Noetica (no cloud needed)
turtle-copilot use noetica
turtle-copilot start

# Full forge status
turtle-gh status

# Health check all integrations
turtle-diagnose
```

## Environment Variables

| Variable | macOS/Linux | Windows |
|---|---|---|
| `ANTHROPIC_API_KEY` | `export ANTHROPIC_API_KEY=sk-...` | `$env:ANTHROPIC_API_KEY = "sk-..."` |
| `GITEA_URL` | `export GITEA_URL=http://gitea:3000` | `$env:GITEA_URL = "http://gitea:3000"` |
| `GITEA_TOKEN` | `export GITEA_TOKEN=...` | `$env:GITEA_TOKEN = "..."` |
| `SOURCEOS_NOETICA_URL` | auto-set by Homebrew cask | auto-set by Chocolatey |

## Claude Code MCP (all platforms)

Add to `~/.claude/settings.json` (macOS/Linux) or `%USERPROFILE%\.claude\settings.json` (Windows):

```json
{
  "mcpServers": {
    "turtleterm": {
      "type": "stdio",
      "command": "turtle-mcp-server"
    }
  }
}
```
