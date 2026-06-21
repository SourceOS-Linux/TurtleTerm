$ErrorActionPreference = 'Stop'
$installDir = "$env:ProgramFiles\TurtleTerm"

Write-Host "Removing TurtleTerm..."

# Remove PATH entry
Uninstall-ChocolateyPath -PathToUninstall "$installDir\bin" -PathType 'Machine'

# Remove environment variables
[Environment]::SetEnvironmentVariable('WEZTERM_CONFIG_FILE', $null, 'Machine')
[Environment]::SetEnvironmentVariable('TURTLE_AGENT_DIR', $null, 'Machine')
[Environment]::SetEnvironmentVariable('TURTLETERM_INSTALL', $null, 'Machine')

# Remove install dir (keep config in AppData)
if (Test-Path $installDir) {
  Remove-Item -Recurse -Force $installDir
  Write-Host "  Removed $installDir"
}

Write-Host "TurtleTerm uninstalled. Config preserved at $env:APPDATA\turtleterm"
