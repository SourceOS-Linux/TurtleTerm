$ErrorActionPreference = 'Stop'

$packageName = 'turtleterm'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$installDir  = "$env:ProgramFiles\TurtleTerm"

# ── WezTerm binary ────────────────────────────────────────────────────────────
$wezTermVersion = '20240203-110809-5046fc22'
$packageArgs = @{
  packageName    = 'wezterm-windows'
  unzipLocation  = $installDir
  url64bit       = "https://github.com/wez/wezterm/releases/download/$wezTermVersion/WezTerm-windows-$wezTermVersion.zip"
  checksum64     = 'SKIP'  # Set to actual SHA256 on release
  checksumType64 = 'sha256'
  silentArgs     = '/S'
}

Write-Host "Installing WezTerm base..."
Install-ChocolateyZipPackage @packageArgs

# ── Python agent scripts ───────────────────────────────────────────────────────
$agentDir = "$installDir\turtle-agent"
New-Item -ItemType Directory -Force -Path $agentDir | Out-Null
New-Item -ItemType Directory -Force -Path "$agentDir\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$agentDir\shell" | Out-Null
New-Item -ItemType Directory -Force -Path "$agentDir\mcp" | Out-Null

# Download agent scripts from GitHub release
$releaseBase = 'https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/assets/sourceos'
$scripts = @(
  'bin/turtle-agentd', 'bin/turtle-agentctl', 'bin/turtle-selftest',
  'bin/turtle-copilot', 'bin/turtle-gh', 'bin/turtle-env',
  'bin/turtle-diagnose', 'bin/turtle-apply', 'bin/turtle-chain',
  'bin/turtle-gitea', 'bin/turtle-ci', 'bin/turtle-review',
  'bin/turtle-watch', 'bin/turtle-netwatch', 'bin/turtle-cost', 'bin/turtle-bg',
  'bin/turtle-dash', 'bin/turtle-pr', 'bin/turtle-issue',
  'bin/turtle-hooks', 'bin/turtle-perf', 'bin/turtle-persona',
  'bin/turtle-files', 'bin/turtle-runbook', 'bin/turtle-session',
  'bin/turtle-sync', 'bin/turtle-voice', 'bin/turtle-plan-view',
  'bin/turtle-synapseiq', 'bin/turtle-tmux', 'bin/turtle-language'
)

foreach ($script in $scripts) {
  $dest = "$agentDir\$script"
  $destDir = Split-Path $dest -Parent
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  try {
    $uri = "$releaseBase/$script"
    Invoke-WebRequest -Uri $uri -OutFile $dest -UseBasicParsing
    Write-Host "  v $script"
  } catch {
    Write-Warning "  ! Failed to download $script -- $($_.Exception.Message)"
  }
}

# Download shell integration
$shellFiles = @(
  'shell/turtle-shell-init.ps1',
  'shell/turtle-agentctl-completions.ps1',
  'shell/turtle-gh-completions.ps1',
  'shell/turtle-copilot-completions.ps1'
)
foreach ($sf in $shellFiles) {
  $dest = "$agentDir\$sf"
  $destDir = Split-Path $dest -Parent
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  try {
    Invoke-WebRequest -Uri "$releaseBase/$sf" -OutFile $dest -UseBasicParsing
  } catch {
    Write-Warning "  ! Shell file not found: $sf"
  }
}

# Download MCP server
try {
  Invoke-WebRequest -Uri "$releaseBase/mcp/turtle-mcp-server" -OutFile "$agentDir\mcp\turtle-mcp-server" -UseBasicParsing
} catch {
  Write-Warning "  ! MCP server download failed"
}

# ── Create .cmd shims so scripts work from PATH ────────────────────────────────
$pythonExe = (Get-Command python -ErrorAction SilentlyContinue)?.Source
if (-not $pythonExe) { $pythonExe = (Get-Command python3 -ErrorAction SilentlyContinue)?.Source }
if (-not $pythonExe) { $pythonExe = 'python' }

$shimDir = "$installDir\bin"
New-Item -ItemType Directory -Force -Path $shimDir | Out-Null

$agentScripts = @(
  'turtle-agentd', 'turtle-agentctl', 'turtle-copilot', 'turtle-gh',
  'turtle-env', 'turtle-diagnose', 'turtle-apply', 'turtle-chain',
  'turtle-gitea', 'turtle-ci', 'turtle-review', 'turtle-watch', 'turtle-netwatch',
  'turtle-cost', 'turtle-bg', 'turtle-dash', 'turtle-pr',
  'turtle-issue', 'turtle-hooks', 'turtle-perf', 'turtle-persona',
  'turtle-files', 'turtle-runbook', 'turtle-session', 'turtle-sync',
  'turtle-voice', 'turtle-plan-view', 'turtle-synapseiq',
  'turtle-selftest', 'turtle-mcp-server'
)

foreach ($s in $agentScripts) {
  $scriptPath = if ($s -eq 'turtle-mcp-server') { "$agentDir\mcp\turtle-mcp-server" } else { "$agentDir\bin\$s" }
  $cmdContent = "@echo off`r`n`"$pythonExe`" `"$scriptPath`" %*"
  Set-Content -Path "$shimDir\$s.cmd" -Value $cmdContent -Encoding ASCII
  Write-Host "  shim: $s.cmd"
}

# Also shim wezterm as turtle-term
$weztermExe = "$installDir\wezterm.exe"
if (Test-Path $weztermExe) {
  $cmdContent = "@echo off`r`n`"$weztermExe`" %*"
  Set-Content -Path "$shimDir\turtle-term.cmd" -Value $cmdContent -Encoding ASCII
  $cmdContent2 = "@echo off`r`nstart `"`" `"$weztermExe`" %*"
  Set-Content -Path "$shimDir\turtleterm.cmd" -Value $cmdContent2 -Encoding ASCII
}

# ── Add to PATH ───────────────────────────────────────────────────────────────
Install-ChocolateyPath -PathToInstall $shimDir -PathType 'Machine'

# ── Config directory ──────────────────────────────────────────────────────────
$configDir = "$env:APPDATA\turtleterm"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
New-Item -ItemType Directory -Force -Path "$configDir\personas" | Out-Null
New-Item -ItemType Directory -Force -Path "$configDir\runbooks" | Out-Null
New-Item -ItemType Directory -Force -Path "$configDir\bg_plans" | Out-Null
New-Item -ItemType Directory -Force -Path "$configDir\copilot_threads" | Out-Null

# ── Copy WezTerm Lua config ───────────────────────────────────────────────────
$luaConfig = "$agentDir\turtleterm.lua"
try {
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SourceOS-Linux/TurtleTerm/main/assets/sourceos/turtleterm.lua' -OutFile $luaConfig -UseBasicParsing
} catch {
  # Write fallback config
  $fallback = @"
local wezterm = require 'wezterm'
local config  = wezterm.config_builder()
config.set_environment_variables = {
  SOURCEOS_TERMINAL_FRONTEND = 'turtle-term',
  TURTLETERM_PROFILE = 'turtleterm-windows',
  TURTLE_AGENT_DIR   = '$($agentDir -replace '\\','\\\\')\\bin',
}
return config
"@
  Set-Content -Path $luaConfig -Value $fallback
}
$env:WEZTERM_CONFIG_FILE = $luaConfig
[Environment]::SetEnvironmentVariable('WEZTERM_CONFIG_FILE', $luaConfig, 'Machine')

# ── Set TURTLE_AGENT_DIR so scripts find each other ───────────────────────────
[Environment]::SetEnvironmentVariable('TURTLE_AGENT_DIR', "$agentDir\bin", 'Machine')
[Environment]::SetEnvironmentVariable('TURTLETERM_INSTALL', $installDir, 'Machine')

Write-Host ""
Write-Host "TurtleTerm v1.4.0 installed." -ForegroundColor Green
Write-Host ""
Write-Host "  Shell integration -- add to your PowerShell profile (`$PROFILE):"
Write-Host "    . `"$agentDir\shell\turtle-shell-init.ps1`""
Write-Host ""
Write-Host "  Start co-pilot:        turtle-copilot start"
Write-Host "  Chat with co-pilot:    turtle-copilot chat"
Write-Host "  Forge status:          turtle-gh status"
Write-Host "  Self-test:             turtle-selftest"
Write-Host ""
Write-Host "  Set ANTHROPIC_API_KEY for Claude-powered features."
Write-Host "  Set GITEA_URL + GITEA_TOKEN for Gitea sovereign forge."
