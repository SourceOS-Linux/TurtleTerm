# TurtleTerm PowerShell integration
# Add to $PROFILE: . "path\to\turtle-shell-init.ps1"
#
# Features:
#   ALT+/ (or F12)   -- AI ghost-text completion
#   ALT+G            -- NL-to-shell (background)
#   Pre-exec timing  -- shows elapsed time after each command
#   RPROMPT          -- elapsed time + active plan step (in prompt)
#   PSReadLine hooks -- AI completion integration

if ($env:_TURTLE_SHELL_INIT_PS1) { return }
$env:_TURTLE_SHELL_INIT_PS1 = '1'

$env:TURTLE_SHELL = 'powershell'
$env:SOURCEOS_TERMINAL_FRONTEND = if ($env:SOURCEOS_TERMINAL_FRONTEND) { $env:SOURCEOS_TERMINAL_FRONTEND } else { 'turtle-term' }
$env:SOURCEOS_WORKSPACE = if ($env:SOURCEOS_WORKSPACE) { $env:SOURCEOS_WORKSPACE } else { 'default' }

if (-not $env:SOURCEOS_TERMINAL_SESSION_ID) {
  try {
    $env:SOURCEOS_TERMINAL_SESSION_ID = "term-$([System.Guid]::NewGuid().ToString('N'))"
  } catch {
    $env:SOURCEOS_TERMINAL_SESSION_ID = "term-$(Get-Date -Format 'yyyyMMddHHmmss')"
  }
}

$_turtle_agent_dir = if ($env:TURTLE_AGENT_DIR) { $env:TURTLE_AGENT_DIR } else { "$env:APPDATA\turtleterm\bin" }
$_turtle_agentctl  = Join-Path $_turtle_agent_dir 'turtle-agentctl'

# ── Dangerous command patterns ─────────────────────────────────────────────────
$_turtle_dangerous_patterns = @(
  'rm\s+-[Rr][Ff]\s+/',
  'rm\s+-[Rr][Ff]\s+~',
  'git\s+push\s+.*--force',
  'git\s+push\s+-f\b',
  'DROP\s+TABLE',
  '\|\s*sh\b',
  'Remove-Item\s+-Recurse\s+-Force\s+[C-Z]:\\$',
  'Format-Volume\b',
  'Clear-Disk\b'
)

function _turtle_check_dangerous {
  param([string]$cmd)
  foreach ($pattern in $_turtle_dangerous_patterns) {
    if ($cmd -match $pattern) {
      Write-Host "`e[33m[!] TurtleTerm policy: dangerous pattern detected -- review before running`e[0m" -NoNewline
      Write-Host ""
      return
    }
  }
}

# ── Timing via PSReadLine ─────────────────────────────────────────────────────
$script:_turtle_cmd_start = $null

Set-PSReadLineOption -AddToHistoryHandler {
  param($line)
  _turtle_check_dangerous $line
  $script:_turtle_cmd_start = [datetime]::UtcNow
  return $true
}

function _turtle_prompt_elapsed {
  if ($script:_turtle_cmd_start) {
    $elapsed = ([datetime]::UtcNow - $script:_turtle_cmd_start).TotalSeconds
    $script:_turtle_cmd_start = $null
    if ($elapsed -ge 0.1) {
      $fmt = if ($elapsed -ge 60) { "{0:mm\:ss}" -f [timespan]::FromSeconds($elapsed) } else { "$([math]::Round($elapsed, 1))s" }
      return " [$fmt]"
    }
  }
  return ""
}

# Extend prompt with elapsed time
$_turtle_original_prompt = if (Test-Path Function:\prompt) { Get-Item Function:\prompt } else { $null }

function prompt {
  $elapsed = _turtle_prompt_elapsed
  $base = if ($script:_turtle_original_prompt) { & $script:_turtle_original_prompt } else { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }
  if ($elapsed) {
    return "$base`e[90m$elapsed`e[0m "
  }
  return $base
}

# ── AI completion (ALT+/) ─────────────────────────────────────────────────────
Set-PSReadLineKeyHandler -Key 'Alt+Slash' -BriefDescription 'TurtleTerm AI Completion' -ScriptBlock {
  $line = $null; $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  if (-not $line.Trim()) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("# (type first, then ALT+/ for AI completion)")
    return
  }
  $cwd = Get-Location
  $branch = try { git branch --show-current 2>$null } catch { "" }
  $payload = @{
    action     = 'ai-complete'
    partial    = $line
    cwd        = $cwd.Path
    git_branch = $branch
  } | ConvertTo-Json -Compress
  try {
    $result = $payload | python "$script:_turtle_agentctl" '--stdio' 2>$null | ConvertFrom-Json
    $suggestion = $result?.data?.completion
    if ($suggestion -and $suggestion -ne $line) {
      [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert($suggestion)
    }
  } catch {}
}

# ── NL-to-shell (ALT+G) ───────────────────────────────────────────────────────
Set-PSReadLineKeyHandler -Key 'Alt+g' -BriefDescription 'TurtleTerm NL-to-Shell' -ScriptBlock {
  $line = $null; $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  if (-not $line.Trim()) { return }
  $payload = @{ action = 'nl-to-shell'; query = $line } | ConvertTo-Json -Compress
  try {
    $result = $payload | python "$script:_turtle_agentctl" '--stdio' 2>$null | ConvertFrom-Json
    $cmd = $result?.data?.command
    if ($cmd) {
      [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert($cmd)
    }
  } catch {}
}

# ── Pre-exec risk check (F2) ──────────────────────────────────────────────────
Set-PSReadLineKeyHandler -Key 'F2' -BriefDescription 'TurtleTerm Risk Check' -ScriptBlock {
  $line = $null; $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  if (-not $line.Trim()) { return }
  $payload = @{ action = 'pre-exec-risk'; command = $line } | ConvertTo-Json -Compress
  try {
    $result = $payload | python "$script:_turtle_agentctl" '--stdio' 2>$null | ConvertFrom-Json
    $score = $result?.data?.score
    $risk  = $result?.data?.risk
    if ($score -and $score -ge 7) {
      Write-Host "`n[RISK $risk score=$score] $($result.data.reasons -join ', ')" -ForegroundColor Red
    } elseif ($score) {
      Write-Host "`n[OK risk=$risk score=$score]" -ForegroundColor Green
    }
  } catch {}
}

# ── turtle-env auto-load ──────────────────────────────────────────────────────
function _turtle_load_project_env {
  $envFile = Join-Path (Get-Location) '.turtle\env.yaml'
  if (Test-Path $envFile) {
    $payload = @{ action = 'env-load'; cwd = (Get-Location).Path } | ConvertTo-Json -Compress
    try {
      $result = $payload | python "$script:_turtle_agentctl" '--stdio' 2>$null | ConvertFrom-Json
      foreach ($entry in $result?.data?.vars.PSObject.Properties) {
        Set-Item "env:$($entry.Name)" $entry.Value
      }
    } catch {}
  }
}

# Auto-load on shell start
_turtle_load_project_env

# ── Convenience aliases ────────────────────────────────────────────────────────
Set-Alias -Name tterm  -Value turtle-term     -ErrorAction SilentlyContinue
Set-Alias -Name tcp    -Value turtle-copilot  -ErrorAction SilentlyContinue
Set-Alias -Name tgh    -Value turtle-gh       -ErrorAction SilentlyContinue
Set-Alias -Name tenv   -Value turtle-env      -ErrorAction SilentlyContinue
Set-Alias -Name tdiag  -Value turtle-diagnose -ErrorAction SilentlyContinue

Write-Host "TurtleTerm shell integration loaded." -ForegroundColor Cyan
Write-Host "  ALT+/  AI completion  |  ALT+G  NL-to-shell  |  F2  risk check" -ForegroundColor DarkGray
