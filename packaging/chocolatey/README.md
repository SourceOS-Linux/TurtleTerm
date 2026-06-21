# TurtleTerm Chocolatey Package

Windows packaging for TurtleTerm v1.4.0.

## Install

```powershell
choco install turtleterm
```

## Build Package Locally

```powershell
cd packaging\chocolatey\turtleterm
choco pack
choco install turtleterm --source .
```

## Publish to Chocolatey Community Repository

```powershell
choco apikey --key YOUR_API_KEY --source https://push.chocolatey.org/
choco push turtleterm.1.4.0.nupkg --source https://push.chocolatey.org/
```

## Environment Variables

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Claude-powered AI features |
| `GITEA_URL` | Gitea sovereign forge primary endpoint |
| `GITEA_TOKEN` | Gitea authentication token |
| `GITHUB_TOKEN` | GitHub fallback token |
| `OLLAMA_HOST` | Ollama endpoint (default: http://localhost:11434) |

## Post-Install

```powershell
# Add to $PROFILE
. "$env:ProgramFiles\TurtleTerm\turtle-agent\shell\turtle-shell-init.ps1"

# Start co-pilot
turtle-copilot start

# Check all integrations
turtle-diagnose
```
