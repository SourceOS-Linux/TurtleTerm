-- TurtleTerm default profile
--
-- Product-facing profile for TurtleTerm. This file is installed as
-- etc/turtle-term/turtleterm.lua and loaded by the turtleterm launcher.

local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

local config = wezterm.config_builder()

local function env(name, fallback)
  local value = os.getenv(name)
  if value == nil or value == '' then
    return fallback
  end
  return value
end

local function basename(path)
  if path == nil then
    return ''
  end
  return string.gsub(path, '(.*[/\\])', '')
end

local function turtle_workspace()
  return env('SOURCEOS_WORKSPACE', 'turtle')
end

local function turtle_domain()
  return env('SOURCEOS_EXECUTION_DOMAIN', 'host')
end

local function turtle_session_id()
  return env('SOURCEOS_TERMINAL_SESSION_ID', '')
end

config.default_prog = nil
config.automatically_reload_config = true
config.check_for_updates = false
config.color_scheme = env('TURTLETERM_COLOR_SCHEME', env('SOURCEOS_TERMINAL_COLOR_SCHEME', 'Builtin Solarized Dark'))
config.font = wezterm.font_with_fallback({
  'JetBrains Mono',
  'Symbols Nerd Font Mono',
  'Noto Color Emoji',
})
config.font_size = tonumber(env('TURTLETERM_FONT_SIZE', env('SOURCEOS_TERMINAL_FONT_SIZE', '12.5')))

config.window_padding = {
  left = 8,
  right = 8,
  top = 6,
  bottom = 6,
}

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.window_decorations = 'RESIZE'
config.audible_bell = 'Disabled'
config.enable_scroll_bar = false
config.scrollback_lines = 20000

config.unix_domains = {
  {
    name = 'turtle-local',
  },
}

config.set_environment_variables = {
  SOURCEOS_TERMINAL_FRONTEND = 'turtle-term',
  SOURCEOS_TERMINAL_PROFILE = 'turtleterm-v0',
  TURTLETERM_PROFILE = 'turtleterm-v0',
}

config.keys = {
  { key = 'Enter', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'Enter', mods = 'CTRL|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'x', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },
  { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
  { key = 'o', mods = 'CTRL|SHIFT', action = act.ShowLauncher },
  {
    key = 's',
    mods = 'CTRL|SHIFT',
    action = act.PromptInputLine {
      description = 'TurtleTerm session note',
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          wezterm.log_info('turtleterm.session_note: ' .. line)
        end
      end),
    },
  },
}

wezterm.on('format-tab-title', function(tab, tabs, panes, config_, hover, max_width)
  local pane = tab.active_pane
  local cwd = ''

  if pane and pane.current_working_dir then
    cwd = basename(tostring(pane.current_working_dir))
  end

  if cwd == '' then
    cwd = 'terminal'
  end

  local domain = turtle_domain()
  local workspace = turtle_workspace()
  return string.format(' 🐢 %s:%s [%s] ', workspace, cwd, domain)
end)

wezterm.on('update-right-status', function(window, pane)
  local workspace = turtle_workspace()
  local domain = turtle_domain()
  local session = turtle_session_id()

  if session ~= '' then
    session = ' · ' .. session
  end

  window:set_right_status(string.format(' 🐢 %s · %s%s ', workspace, domain, session))
end)

wezterm.on('gui-startup', function(cmd)
  local workspace = turtle_workspace()
  pcall(function()
    mux.set_active_workspace(workspace)
  end)
end)

return config
