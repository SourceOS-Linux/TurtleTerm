# Kill any running WezTerm processes before upgrade
Get-Process -Name 'wezterm*' -ErrorAction SilentlyContinue | Stop-Process -Force
