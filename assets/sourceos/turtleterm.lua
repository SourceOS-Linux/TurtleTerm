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

-- iTerm2 default color palette
local iterm2_colors = {
  foreground = '#c7c7c7',
  background = '#000000',
  cursor_bg = '#ffffff',
  cursor_fg = '#000000',
  cursor_border = '#ffffff',
  selection_bg = '#4d4d4d',
  selection_fg = '#ffffff',
  ansi = {
    '#000000', '#c91b00', '#00c200', '#c7c400',
    '#0225c7', '#ca30c7', '#00c5c7', '#c7c7c7',
  },
  brights = {
    '#686868', '#ff6e67', '#5ffa68', '#fffc67',
    '#6871ff', '#ff77ff', '#60fdff', '#ffffff',
  },
}

if env('TURTLETERM_COLOR_SCHEME', '') ~= '' then
  config.color_scheme = env('TURTLETERM_COLOR_SCHEME', '')
elseif env('SOURCEOS_TERMINAL_COLOR_SCHEME', '') ~= '' then
  config.color_scheme = env('SOURCEOS_TERMINAL_COLOR_SCHEME', '')
else
  config.colors = iterm2_colors
end

config.font = wezterm.font_with_fallback({
  'Menlo',
  'Monaco',
  'Courier New',
  'Symbols Nerd Font Mono',
})
config.font_size = tonumber(env('TURTLETERM_FONT_SIZE', env('SOURCEOS_TERMINAL_FONT_SIZE', '13.0')))

config.window_padding = {
  left = 5,
  right = 5,
  top = 5,
  bottom = 5,
}

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.window_decorations = 'TITLE | RESIZE'
config.audible_bell = 'Disabled'
config.enable_scroll_bar = false
config.scrollback_lines = 20000

config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 600
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

config.window_background_opacity = 1.0
config.macos_window_background_blur = 0

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

-- ============================================================
-- Policy TUI overlay
-- ============================================================

local function turtle_policy_gate()
  return act.PromptInputLine {
    description = '🐢 TurtleTerm Policy Gate — command to evaluate:',
    initial_value = '',
    action = wezterm.action_callback(function(window, pane, line)
      if not line or line == '' then return end
      local success, stdout, stderr = wezterm.run_child_process({
        'turtle-agentctl', '--stdio', 'policy-evaluate', line,
      })
      if not success or (not stdout or stdout == '') then
        window:toast_notification('TurtleTerm Policy', 'evaluation failed — is turtle-agentctl in PATH?\n' .. (stderr or ''), nil, 6000)
        return
      end
      -- Extract decision and reason from JSON without requiring a parser.
      local decision = stdout:match('"decision"%s*:%s*"([^"]+)"') or 'unknown'
      local reason   = stdout:match('"reason"%s*:%s*"([^"]+)"') or ''
      if decision == 'allow' then
        window:toast_notification('TurtleTerm Policy', 'ALLOW — sending: ' .. line, nil, 3000)
        pane:send_text(line .. '\n')
      elseif decision == 'deny' then
        window:toast_notification('TurtleTerm Policy', 'DENY: ' .. reason, nil, 6000)
      elseif decision == 'ask' then
        window:perform_action(
          act.PromptInputLine {
            description = '🐢 Policy asks: ' .. reason .. ' — approve? [y/n]',
            initial_value = 'n',
            action = wezterm.action_callback(function(w2, p2, answer)
              if answer == 'y' or answer == 'Y' then
                p2:send_text(line .. '\n')
              else
                w2:toast_notification('TurtleTerm Policy', 'Blocked at user gate.', nil, 3000)
              end
            end),
          },
          pane
        )
      else
        window:toast_notification('TurtleTerm Policy', decision:upper() .. (reason ~= '' and (': ' .. reason) or ''), nil, 4000)
      end
    end),
  }
end

-- ============================================================
-- Shell auto-source integration
-- ============================================================

local function find_shell_init_dir()
  local explicit = env('TURTLE_SHELL_INIT_DIR', '')
  if explicit ~= '' then return explicit end
  -- Relative to this config file (dev layout: assets/sourceos/shell/)
  local cfg = wezterm.config_dir
  for _, rel in ipairs({ '../../assets/sourceos/shell', '../shell', 'shell' }) do
    local candidate = cfg .. '/' .. rel
    local f = io.open(candidate .. '/turtle-shell-init.bash')
    if f then f:close(); return candidate end
  end
  -- Common install prefixes
  local home = env('HOME', '')
  for _, p in ipairs({
    '/opt/homebrew/share/turtleterm/shell',
    '/usr/local/share/turtleterm/shell',
    home .. '/.local/share/turtleterm/shell',
  }) do
    local f = io.open(p .. '/turtle-shell-init.bash')
    if f then f:close(); return p end
  end
  return nil
end

local function write_zsh_init_shim(init_dir)
  local home = env('HOME', '')
  local state_home = env('XDG_STATE_HOME', home .. '/.local/state')
  local shim_dir = state_home .. '/sourceos/terminal/zsh-init'
  os.execute('mkdir -p ' .. shim_dir)
  local f = io.open(shim_dir .. '/.zshenv', 'w')
  if not f then
    wezterm.log_warn('turtleterm: could not write zsh shim to ' .. shim_dir)
    return nil
  end
  f:write(string.format([[
# TurtleTerm zsh auto-integration shim. Auto-generated.
_tdot_orig="${ZDOTDIR_ORIGINAL:-${HOME}}"
unset ZDOTDIR
[ -f "${_tdot_orig}/.zshenv" ] && source "${_tdot_orig}/.zshenv"
_tinit="%s"
[ -n "${_tinit}" ] && [ -f "${_tinit}/turtle-shell-init.zsh" ] && source "${_tinit}/turtle-shell-init.zsh"
unset _tdot_orig _tinit
]], init_dir))
  f:close()
  return shim_dir
end

local turtle_shell_init_dir = find_shell_init_dir()

if turtle_shell_init_dir then
  config.set_environment_variables['TURTLE_SHELL_INIT_DIR'] = turtle_shell_init_dir
  -- bash: BASH_ENV is sourced for all non-interactive bash invocations
  config.set_environment_variables['BASH_ENV'] = turtle_shell_init_dir .. '/turtle-shell-init.bash'
  -- zsh: write a ZDOTDIR shim that sources the turtle init before the user's real .zshenv
  local zsh_shim = write_zsh_init_shim(turtle_shell_init_dir)
  if zsh_shim then
    -- Preserve any existing ZDOTDIR so the shim can restore it
    local orig_zdotdir = env('ZDOTDIR', env('HOME', ''))
    config.set_environment_variables['ZDOTDIR_ORIGINAL'] = orig_zdotdir
    config.set_environment_variables['ZDOTDIR'] = zsh_shim
  end
end

-- ============================================================
-- Hyperlink rules
-- ============================================================

config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- file:// with line numbers (e.g. from compiler errors)
table.insert(config.hyperlink_rules, {
  regex = [[\bfile://([^\s"'<>]+)(?::(\d+)(?::(\d+))?)?\b]],
  format = "$0",
})
-- Rust/Go/Python "at path:line:col" patterns
table.insert(config.hyperlink_rules, {
  regex = [[(?:at |in )([A-Za-z0-9_./-]+\.[A-Za-z0-9]+):(\d+)(?::(\d+))?]],
  format = "file://$1",
})

-- ============================================================
-- Mouse bindings
-- ============================================================

config.mouse_bindings = {
  -- CMD+click to open hyperlinks (WezTerm default is ALT+click)
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.OpenLinkAtMouseCursor,
  },
}

-- ============================================================
-- Agent action helpers (called from key bindings)
-- ============================================================

local function agentctl(args)
  return wezterm.action_callback(function(window, pane)
    local ok, stdout, _ = wezterm.run_child_process(args)
    if ok and stdout and stdout ~= '' then
      return stdout
    end
    return nil
  end)
end

local function turtle_explain_selection()
  return wezterm.action_callback(function(window, pane)
    local sel = window:get_selection_text_for_pane(pane)
    if not sel or sel == '' then
      window:toast_notification('TurtleTerm', 'No text selected — select output first, then CTRL+SHIFT+E.', nil, 4000)
      return
    end
    window:toast_notification('TurtleTerm', 'Asking Noetica to explain…', nil, 2000)
    local ok, stdout, _ = wezterm.run_child_process({
      'turtle-agentctl', 'explain-selection', sel,
    })
    if ok and stdout and stdout ~= '' then
      local data = {}
      pcall(function() data = wezterm.json_parse(stdout) end)
      local explanation = (data.data and data.data.explanation) or stdout:sub(1, 300)
      window:toast_notification('TurtleTerm Explain', explanation, nil, 12000)
    else
      window:toast_notification('TurtleTerm', 'Noetica unreachable — start dev-backend.sh on :8080', nil, 6000)
    end
  end)
end

local function turtle_nl_to_shell()
  return act.PromptInputLine {
    description = '🐢 NL→Shell: describe what you want to do',
    initial_value = '',
    action = wezterm.action_callback(function(window, pane, line)
      if not line or line == '' then return end
      window:toast_notification('TurtleTerm', 'Generating command…', nil, 2000)
      local ok, stdout, _ = wezterm.run_child_process({
        'turtle-agentctl', 'nl-to-shell', line,
      })
      if ok and stdout and stdout ~= '' then
        local data = {}
        pcall(function() data = wezterm.json_parse(stdout) end)
        local cmd = (data.data and data.data.command) or ''
        if cmd ~= '' then
          pane:send_text(cmd)
          window:toast_notification('TurtleTerm NL→Shell', cmd, nil, 6000)
        else
          window:toast_notification('TurtleTerm', 'Noetica returned empty — start dev-backend.sh on :8080', nil, 6000)
        end
      else
        window:toast_notification('TurtleTerm', 'Noetica unreachable — start dev-backend.sh on :8080', nil, 6000)
      end
    end),
  }
end

local function turtle_atlas_context()
  return wezterm.action_callback(function(window, pane)
    local cwd = ''
    if pane and pane.current_working_dir then
      cwd = tostring(pane.current_working_dir):gsub('file://[^/]*', '')
    end
    local ok, stdout, _ = wezterm.run_child_process({
      'turtle-agentctl', 'atlas-context', cwd,
    })
    if ok and stdout and stdout ~= '' then
      local data = {}
      pcall(function() data = wezterm.json_parse(stdout) end)
      local found = data.data and data.data.found
      if not found then
        window:toast_notification('TurtleTerm Atlas', 'No .atlas/ directory found in this project.', nil, 4000)
      else
        local count = (data.data and data.data.entry_count) or 0
        local atlas_dir = (data.data and data.data.atlas_dir) or ''
        window:toast_notification('TurtleTerm Atlas', string.format('%d entries at %s', count, atlas_dir), nil, 5000)
      end
    else
      window:toast_notification('TurtleTerm', 'atlas-context failed', nil, 4000)
    end
  end)
end

config.keys = {
  -- Prompt jumping (OSC 133 marks required — turtle-shell-init provides them)
  { key = 'UpArrow', mods = 'CMD', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'CMD', action = act.ScrollToPrompt(1) },

  -- Command blocks: copy last output / last command to clipboard
  {
    key = 'b', mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      local zones = {}
      pcall(function() zones = pane:get_semantic_zones() end)
      if #zones == 0 then
        window:toast_notification('TurtleTerm', 'No blocks — enable shell integration (turtle-shell-init).', nil, 4000)
        return
      end
      local last_output = nil
      for _, z in ipairs(zones) do
        if z.semantic_type == 'Output' then last_output = z end
      end
      if not last_output then
        window:toast_notification('TurtleTerm', 'No output block in current scrollback.', nil, 3000)
        return
      end
      local text = ''
      pcall(function() text = pane:get_text_from_semantic_zone(last_output) end)
      if text == '' then
        window:toast_notification('TurtleTerm', 'Output block is empty.', nil, 3000)
        return
      end
      local f = io.popen('pbcopy 2>/dev/null || xclip -selection clipboard 2>/dev/null || wl-copy 2>/dev/null', 'w')
      if f then
        f:write(text)
        f:close()
        window:toast_notification('TurtleTerm Block', string.format('Copied %d chars (last output).', #text), nil, 3000)
      end
    end),
  },
  {
    key = 'b', mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local zones = {}
      pcall(function() zones = pane:get_semantic_zones() end)
      local last_input = nil
      for _, z in ipairs(zones) do
        if z.semantic_type == 'Input' then last_input = z end
      end
      if not last_input then
        window:toast_notification('TurtleTerm', 'No command block found.', nil, 3000)
        return
      end
      local text = ''
      pcall(function() text = pane:get_text_from_semantic_zone(last_input) end)
      text = text:gsub('^%s+', ''):gsub('%s+$', '')
      if text ~= '' then
        local f = io.popen('pbcopy 2>/dev/null || xclip -selection clipboard 2>/dev/null || wl-copy 2>/dev/null', 'w')
        if f then f:write(text); f:close() end
        window:toast_notification('TurtleTerm Command', text:sub(1, 100), nil, 3000)
      end
    end),
  },

  -- Agent intelligence
  { key = 'e', mods = 'CTRL|SHIFT', action = turtle_explain_selection() },
  { key = 'n', mods = 'CTRL|SHIFT', action = turtle_nl_to_shell() },
  { key = 'a', mods = 'CTRL|SHIFT', action = turtle_atlas_context() },

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
  { key = 'g', mods = 'CTRL|SHIFT', action = turtle_policy_gate() },
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
  local proc = ''

  if pane and pane.current_working_dir then
    local raw = tostring(pane.current_working_dir)
    cwd = raw:gsub('file://[^/]*', '')
    local home = os.getenv('HOME') or ''
    if home ~= '' then
      cwd = cwd:gsub('^' .. home, '~')
    end
  end

  if pane and pane.foreground_process_name then
    proc = basename(pane.foreground_process_name)
  end

  local label
  if proc ~= '' and proc ~= 'zsh' and proc ~= 'bash' and proc ~= 'fish' then
    label = proc .. ' — ' .. (cwd ~= '' and cwd or '~')
  else
    label = cwd ~= '' and cwd or '~'
  end

  local idx = tab.tab_index + 1
  return string.format(' %d  %s ', idx, label)
end)

wezterm.on('update-right-status', function(window, pane)
  local domain = turtle_domain()
  if domain ~= 'host' then
    window:set_right_status(string.format('  %s  ', domain))
  else
    window:set_right_status('')
  end
end)

wezterm.on('update-left-status', function(window, pane)
  local parts = {}

  -- Git branch from pane cwd
  if pane and pane.current_working_dir then
    local cwd = tostring(pane.current_working_dir):gsub('file://[^/]*', '')
    if cwd ~= '' then
      local ok, stdout, _ = wezterm.run_child_process({
        'git', '-C', cwd, 'branch', '--show-current',
      })
      if ok and stdout and stdout:match('%S') then
        local branch = stdout:match('([^\n]+)')
        if branch then
          table.insert(parts, ' \xe2\x8e\x87 ' .. branch)  -- ⎇ UTF-8
        end
      end
    end
  end

  -- Last exit code from state file
  local home = os.getenv('HOME') or ''
  local xdg_state = os.getenv('XDG_STATE_HOME') or (home .. '/.local/state')
  local exit_file = xdg_state .. '/sourceos/terminal/last_exit'
  local f = io.open(exit_file, 'r')
  if f then
    local code = f:read('*n')
    f:close()
    if code and code ~= 0 then
      table.insert(parts, ' \xe2\x9c\x97 ' .. tostring(code))  -- ✗
    end
  end

  -- Block count from semantic zones (OSC 133)
  local block_count = 0
  pcall(function()
    local zones = pane:get_semantic_zones()
    for _, z in ipairs(zones) do
      if z.semantic_type == 'Output' then
        block_count = block_count + 1
      end
    end
  end)
  if block_count > 0 then
    table.insert(parts, ' \xe2\x96\xa4 ' .. block_count)  -- ▤ block icon
  end

  if #parts > 0 then
    window:set_left_status(table.concat(parts, '  ') .. '  ')
  else
    window:set_left_status('')
  end
end)

wezterm.on('gui-startup', function(cmd)
  local workspace = turtle_workspace()
  pcall(function()
    mux.set_active_workspace(workspace)
  end)
end)

return config
