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
    -- Write selection to temp file so the subprocess shell can read it
    local tmp = '/tmp/turtle-explain-sel.txt'
    local f = io.open(tmp, 'w')
    if f then f:write(sel); f:close() end
    -- Open a right split pane that runs the explain and shows the result inline
    window:perform_action(
      act.SpawnCommandInNewPane {
        direction = 'Right',
        size = { Percent = 40 },
        command = {
          args = {
            'sh', '-c',
            'clear; echo "=== TurtleTerm Explain ==="; echo; sel=$(cat /tmp/turtle-explain-sel.txt); turtle-agentctl explain-selection "$sel" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\'data\',{}).get(\'explanation\',\'(no response)\'))" 2>/dev/null || echo "(could not reach AI)"; echo; printf "press Enter to close... "; read -r _',
          },
        },
      },
      pane
    )
    window:toast_notification('TurtleTerm', 'Explaining…', nil, 2000)
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

-- Feature: CTRL+SPACE inline AI ghost-text completion
-- Reads the current Input zone, runs nl-to-shell on partial text, replaces with suggestion.
local function turtle_ai_complete()
  return wezterm.action_callback(function(window, pane)
    local input_text = ''
    pcall(function()
      local zones = pane:get_semantic_zones()
      for _, z in ipairs(zones) do
        if z.semantic_type == 'Input' then
          input_text = pane:get_text_from_semantic_zone(z)
        end
      end
    end)
    input_text = input_text:gsub('^%s+', ''):gsub('%s+$', '')
    if input_text == '' then
      window:toast_notification('TurtleTerm', 'Start typing first, then CTRL+SPACE for AI completion.', nil, 2500)
      return
    end
    local ok, stdout, _ = wezterm.run_child_process({ 'turtle-agentctl', 'nl-to-shell', input_text })
    if ok and stdout and stdout ~= '' then
      local data = {}
      pcall(function() data = wezterm.json_parse(stdout) end)
      local cmd = (data.data and data.data.command) or ''
      if cmd ~= '' and cmd ~= input_text then
        pane:send_text('\x15')  -- Ctrl+U — clear line
        pane:send_text(cmd)
        window:toast_notification('TurtleTerm AI', cmd:sub(1, 80), nil, 3000)
      else
        window:toast_notification('TurtleTerm AI', 'No better suggestion — keeping your input.', nil, 2000)
      end
    else
      window:toast_notification('TurtleTerm', 'AI unavailable (set ANTHROPIC_API_KEY or start Noetica).', nil, 3000)
    end
  end)
end

-- Feature: CTRL+R history fuzzy picker from event stream
local function turtle_history_search()
  return wezterm.action_callback(function(window, pane)
    local home = os.getenv('HOME') or ''
    local xdg_state = os.getenv('XDG_STATE_HOME') or (home .. '/.local/state')
    local events_file = xdg_state .. '/sourceos/terminal/events.ndjson'
    local choices = {}
    local seen = {}

    -- Read from turtle event stream (most accurate)
    local f = io.open(events_file, 'r')
    if f then
      local lines = {}
      for line in f:lines() do table.insert(lines, line) end
      f:close()
      for i = #lines, 1, -1 do
        local ok, evt = pcall(function() return wezterm.json_parse(lines[i]) end)
        if ok and evt and evt.event and evt.event.event_type == 'command.completed' then
          local cmd = evt.event.command or ''
          if cmd ~= '' and not seen[cmd] then
            seen[cmd] = true
            table.insert(choices, { label = cmd, id = cmd })
            if #choices >= 100 then break end
          end
        end
      end
    end

    -- Fallback: shell history files
    if #choices == 0 then
      local ok, out, _ = wezterm.run_child_process({
        'sh', '-c', 'tail -n 100 "${HISTFILE:-$HOME/.zsh_history}" 2>/dev/null || tail -n 100 ~/.bash_history 2>/dev/null'
      })
      if ok and out then
        for line in out:gmatch('[^\n]+') do
          local cmd = line:match('^: %d+:%d+;(.+)$') or line
          cmd = cmd:gsub('^%s+', ''):gsub('%s+$', '')
          if cmd ~= '' and not seen[cmd] then
            seen[cmd] = true
            table.insert(choices, { label = cmd, id = cmd })
          end
        end
      end
    end

    if #choices == 0 then
      window:toast_notification('TurtleTerm History', 'No history yet — run some commands first.', nil, 3000)
      return
    end

    window:perform_action(
      act.InputSelector {
        action = wezterm.action_callback(function(_, p2, id, _)
          if id then p2:send_text(id) end
        end),
        title = 'TurtleTerm History  (fuzzy search)',
        choices = choices,
        fuzzy = true,
      },
      pane
    )
  end)
end

-- Feature: CTRL+SHIFT+R AI history search (NL query → smart command reconstruction)
local function turtle_history_ai_search()
  return act.PromptInputLine {
    description = '🐢 AI History: describe what you want to do (recreate or find)',
    initial_value = '',
    action = wezterm.action_callback(function(window, pane, line)
      if not line or line == '' then return end
      local ok, stdout, _ = wezterm.run_child_process({
        'turtle-agentctl', 'nl-to-shell', line,
      })
      if ok and stdout and stdout ~= '' then
        local data = {}
        pcall(function() data = wezterm.json_parse(stdout) end)
        local cmd = (data.data and data.data.command) or ''
        if cmd ~= '' then
          pane:send_text(cmd)
          window:toast_notification('TurtleTerm AI History', cmd, nil, 5000)
        end
      else
        window:toast_notification('TurtleTerm', 'AI unavailable', nil, 3000)
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

-- ============================================================
-- Stored Workflows (Feature 4)
-- ============================================================

local function parse_workflows(content)
  local workflows = {}
  local current = {}
  for line in content:gmatch('[^\n]+') do
    local name = line:match('^%- name:%s*"?([^"]+)"?%s*$')
    local cmd  = line:match('^  command:%s*"?([^"]+)"?%s*$')
    if name then
      if current.name then table.insert(workflows, current) end
      current = { name = name }
    elseif cmd and current.name then
      current.command = cmd
    end
  end
  if current.name then table.insert(workflows, current) end
  return workflows
end

local turtle_builtin_workflows = {
  { name = 'Show disk usage by directory',      command = 'du -sh */ | sort -rh | head -20' },
  { name = 'Git log graph (last 20)',            command = 'git log --oneline --graph --decorate -20' },
  { name = 'Find large files (>10MB)',           command = "find . -size +10M -not -path './.git/*' | sort" },
  { name = 'Show listening ports',               command = 'lsof -iTCP -sTCP:LISTEN -n -P' },
  { name = 'Watch system resources',             command = 'top -o cpu' },
  { name = 'Recent git changes',                 command = 'git diff --stat HEAD~5..HEAD' },
  { name = 'Docker containers',                  command = "docker ps -a --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'" },
  { name = 'Show PATH entries',                  command = "echo $PATH | tr ':' '\\n'" },
}

local function turtle_workflows()
  return wezterm.action_callback(function(window, pane)
    local workflows = turtle_builtin_workflows
    local home = os.getenv('HOME') or ''
    local wf_path = home .. '/.config/turtleterm/workflows.yaml'
    local wf_file = io.open(wf_path, 'r')
    if wf_file then
      local content = wf_file:read('*a')
      wf_file:close()
      local parsed = parse_workflows(content)
      if #parsed > 0 then workflows = parsed end
    end
    local choices = {}
    for i, wf in ipairs(workflows) do
      table.insert(choices, { label = string.format('%d. %s', i, wf.name), id = tostring(i) })
    end
    window:perform_action(
      act.InputSelector {
        action = wezterm.action_callback(function(w, p, id, label)
          if not id then return end
          local idx = tonumber(id)
          if idx and workflows[idx] then
            p:send_text(workflows[idx].command)
            w:toast_notification('TurtleTerm Workflows', workflows[idx].name, nil, 3000)
          end
        end),
        title = 'TurtleTerm Workflows',
        choices = choices,
        fuzzy = true,
      },
      pane
    )
  end)
end

-- ============================================================
-- Trigger system defaults (Feature 5)
-- ============================================================

config.turtle_triggers = {
  { pattern = 'Error:',            label = 'error detected',    action = 'notify' },
  { pattern = 'FAILED',            label = 'failure',           action = 'notify' },
  { pattern = 'Permission denied', label = 'permission error',  action = 'notify' },
  { pattern = 'panic:',            label = 'panic',             action = 'notify' },
  { pattern = 'fatal:',            label = 'fatal error',       action = 'notify' },
}

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
  { key = 'e', mods = 'CTRL|SHIFT',   action = turtle_explain_selection() },
  { key = 'n', mods = 'CTRL|SHIFT',   action = turtle_nl_to_shell() },
  { key = 'a', mods = 'CTRL|SHIFT',   action = turtle_atlas_context() },
  { key = 'Space', mods = 'CTRL',     action = turtle_ai_complete() },       -- AI ghost-text complete
  { key = 'r', mods = 'CTRL',         action = turtle_history_search() },    -- History fuzzy picker
  { key = 'r', mods = 'CTRL|SHIFT',   action = turtle_history_ai_search() }, -- AI history search

  { key = 'Enter', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'Enter', mods = 'CTRL|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'CTRL|SHIFT', action = turtle_workflows() },
  { key = 'q', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
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
  -- Feature 3: SSH profile indicator
  local proc = ''
  pcall(function() proc = pane:get_foreground_process_name() or '' end)
  local cwd_uri = ''
  pcall(function() cwd_uri = tostring(pane.current_working_dir) or '' end)
  local is_ssh = proc:find('ssh') ~= nil or cwd_uri:find('^ssh://') ~= nil
  if is_ssh then
    window:set_right_status('  \xe2\x87\x84 ssh  ')  -- ⇄ ssh
  elseif domain ~= 'host' then
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

  -- First-run shell integration hint (fires once per session after gui-startup)
  if wezterm.GLOBAL.check_shell_integration then
    wezterm.GLOBAL.check_shell_integration = nil
    if not os.getenv('TURTLE_SHELL_INIT_DIR') then
      window:toast_notification(
        'TurtleTerm — Shell Integration',
        'Shell integration not active.\nRun: turtleterm --install-shell-integration\n(enables prompt marks, AI context, dangerous-command warnings)',
        nil, 9000
      )
    end
  end

  -- Last exit code + timing from state files
  local home = os.getenv('HOME') or ''
  local xdg_state = os.getenv('XDG_STATE_HOME') or (home .. '/.local/state')
  local exit_file = xdg_state .. '/sourceos/terminal/last_exit'
  local exit_content = ''
  local f = io.open(exit_file, 'r')
  if f then
    exit_content = f:read('*l') or ''
    f:close()
    local code = tonumber(exit_content) or 0
    if code ~= 0 then
      table.insert(parts, ' \xe2\x9c\x97 ' .. tostring(code))  -- ✗
    end
  end

  -- Command timing (⏱)
  local dur_file = xdg_state .. '/sourceos/terminal/last_duration'
  local df = io.open(dur_file, 'r')
  if df then
    local dur = df:read('*n')
    df:close()
    if dur and dur > 1 then
      local dur_str
      if dur < 60 then
        dur_str = string.format('%.0fs', dur)
      elseif dur < 3600 then
        dur_str = string.format('%dm%ds', math.floor(dur / 60), dur % 60)
      else
        dur_str = string.format('%dh%dm', math.floor(dur / 3600), math.floor((dur % 3600) / 60))
      end
      table.insert(parts, ' \xe2\x8f\xb1 ' .. dur_str)  -- ⏱
    end
  end

  -- SynapseIQ diagnostic count — auto-fire on non-zero exit when file paths detected in output
  if exit_content ~= (wezterm.GLOBAL.last_checked_exit or '') then
    wezterm.GLOBAL.last_checked_exit = exit_content
    local exit_num = tonumber(exit_content) or 0
    if exit_num ~= 0 then
      local last_out = ''
      pcall(function()
        local zones = pane:get_semantic_zones()
        for _, z in ipairs(zones) do
          if z.semantic_type == 'Output' then
            last_out = pane:get_text_from_semantic_zone(z) or ''
          end
        end
      end)
      local file_found = last_out:match('([%w_/%.%-]+%.[a-zA-Z][a-zA-Z0-9]*):%d+')
      if file_found and file_found:match('%.[a-z]+$') then
        local ok2, diag_out, _ = wezterm.run_child_process({ 'turtle-language', 'diagnostics', file_found })
        if ok2 and diag_out and diag_out ~= '' then
          local ddata = {}
          pcall(function() ddata = wezterm.json_parse(diag_out) end)
          local count = (ddata.data and ddata.data.diagnostic_count) or 0
          wezterm.GLOBAL.last_diag_count = count > 0 and count or nil
          wezterm.GLOBAL.last_diag_file = count > 0 and file_found or nil
        end
      else
        wezterm.GLOBAL.last_diag_count = nil
      end
    else
      wezterm.GLOBAL.last_diag_count = nil
    end
  end
  if wezterm.GLOBAL.last_diag_count then
    table.insert(parts, ' \xe2\xac\xa1 ' .. wezterm.GLOBAL.last_diag_count)  -- ⬡ N issues
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

  -- Pending command injection (from terminal_execute_with_confirmation MCP tool)
  local pending_path = xdg_state .. '/sourceos/terminal/pending_command'
  local pf = io.open(pending_path, 'r')
  if pf then
    local cmd_text = pf:read('*a')
    pf:close()
    os.remove(pending_path)
    if cmd_text and cmd_text ~= '' then
      cmd_text = cmd_text:match('^%s*(.-)%s*$')  -- trim
      pane:send_text(cmd_text)
      window:toast_notification('TurtleTerm Agent', 'Command ready (press Enter): ' .. cmd_text:sub(1, 60), nil, 4000)
    end
  end

  -- Trigger system: check last output zone against configured patterns
  local triggers = config.turtle_triggers or {}
  if #triggers > 0 then
    local last_output = ''
    pcall(function()
      local zones = pane:get_semantic_zones()
      for _, z in ipairs(zones) do
        if z.semantic_type == 'Output' then
          last_output = pane:get_text_from_semantic_zone(z)
        end
      end
    end)
    if last_output ~= '' then
      local last_trigger_key = '_turtle_last_trigger_' .. tostring(#last_output)
      if not wezterm.GLOBAL[last_trigger_key] then
        wezterm.GLOBAL[last_trigger_key] = true
        for _, trigger in ipairs(triggers) do
          if last_output:find(trigger.pattern) then
            if trigger.action == 'notify' then
              window:toast_notification('TurtleTerm Trigger', trigger.label .. ': ' .. trigger.pattern, nil, 4000)
            end
          end
        end
      end
    end
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
  -- Signal update-left-status to show shell integration hint if not active
  wezterm.GLOBAL.check_shell_integration = true
end)

return config
