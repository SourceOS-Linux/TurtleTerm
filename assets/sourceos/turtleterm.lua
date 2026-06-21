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

-- Session persistence — keep panes visible after process exits, warn before close
config.exit_behavior = 'Hold'
config.exit_behavior_messaging = 'Brief'
config.window_close_confirmation = 'AlwaysPrompt'
config.skip_close_confirmation_for_processes_named = {
  'bash', 'zsh', 'fish', 'sh',
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

-- ============================================================
-- BearBrowser URL routing
-- open-uri event fires with the actual URL → route to BearBrowser
-- if reachable; otherwise fall back to system open.
-- ============================================================

local _bb_reachable = nil
local _bb_checked_at = 0

local function bearbrowser_reachable()
  local now = os.time()
  if _bb_reachable ~= nil and (now - _bb_checked_at) < 30 then
    return _bb_reachable
  end
  local port = os.getenv('BEARBROWSER_A2A_PORT') or '9473'
  local ok, _, _ = wezterm.run_child_process({
    'curl', '-sf', '--max-time', '1', 'http://127.0.0.1:' .. port .. '/health',
  })
  _bb_reachable = ok
  _bb_checked_at = now
  return ok
end

-- open-uri is fired whenever WezTerm would open a hyperlink.
-- Returning false lets WezTerm fall back to the default system open.
wezterm.on('open-uri', function(window, pane, uri)
  -- Only intercept http(s) URLs — leave file:// and mailto: to the OS
  if not uri:match('^https?://') then return false end

  if bearbrowser_reachable() then
    -- Send to BearBrowser via CLI (non-blocking)
    local bb_cmd = os.getenv('BEARBROWSER_CLI') or 'bearbrowser'
    local ok, _, _ = wezterm.run_child_process({ bb_cmd, 'open', uri })
    if ok then
      window:toast_notification('TurtleTerm', '⇒ BearBrowser: ' .. uri:sub(1, 60), nil, 2500)
      return true  -- handled — suppress default open
    end
  end
  -- BearBrowser not available — let WezTerm open normally
  return false
end)

config.mouse_bindings = {
  -- CMD+click opens links (fires the open-uri event above)
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Right-click entry appended below after turtle_block_context_menu is defined
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

-- Synchronous agentctl call: returns parsed JSON or nil
local function turtle_agentctl_json(args)
  local full_args = { 'turtle-agentctl', '--stdio' }
  for _, v in ipairs(args) do table.insert(full_args, v) end
  local ok, stdout, _ = wezterm.run_child_process(full_args)
  if ok and stdout and stdout ~= '' then
    local parsed = wezterm.json_parse(stdout)
    return parsed
  end
  return nil
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

-- Feature: CTRL+SHIFT+D — diagnose last output zone in a split pane
local function turtle_diagnose()
  return wezterm.action_callback(function(window, pane)
    local last_out = ''
    pcall(function()
      local zones = pane:get_semantic_zones()
      for _, z in ipairs(zones) do
        if z.semantic_type == 'Output' then
          last_out = pane:get_text_from_semantic_zone(z) or ''
        end
      end
    end)
    -- Find file:line pattern in output
    local file_found = last_out:match('([%w_/%.%-]+%.[a-zA-Z][a-zA-Z0-9]*):%d+')
    if not file_found then
      -- Try current working directory
      local cwd = ''
      pcall(function() cwd = tostring(pane.current_working_dir):gsub('file://[^/]*', '') end)
      if cwd ~= '' then
        window:perform_action(
          act.SpawnCommandInNewPane {
            direction = 'Right', size = { Percent = 40 },
            command = { args = { 'sh', '-c',
              'clear; echo "=== SynapseIQ Diagnostics ==="; echo; echo "No file path found in last output."; echo; echo "Tip: run a compiler or linter first, then CTRL+SHIFT+D"; echo; printf "press Enter to close... "; read -r _'
            }},
          }, pane
        )
      else
        window:toast_notification('TurtleTerm', 'No file path found in last output.', nil, 3000)
      end
      return
    end
    -- Write a small formatter script to tmp so we avoid shell-quoting hell
    local fmt = io.open('/tmp/turtle-diag-fmt.py', 'w')
    if fmt then
      fmt:write([[
import json, sys
raw = sys.stdin.read()
try:
    d = json.loads(raw).get('data', {})
    diags = d.get('diagnostics', [])
    if not diags:
        print('  no issues found')
    for i in diags:
        ln = i.get('line', 0) + 1
        sev = i.get('severity', '?')
        msg = i.get('message', '?')
        print(f'  line {ln}: [{sev}] {msg}')
except Exception as e:
    print(raw[:500])
]])
      fmt:close()
    end
    window:perform_action(
      act.SpawnCommandInNewPane {
        direction = 'Right', size = { Percent = 45 },
        command = { args = { 'sh', '-c', string.format(
          'clear; printf "=== SynapseIQ Diagnostics: %s ===\\n\\n"; '..
          'turtle-language diagnostics %s 2>/dev/null | python3 /tmp/turtle-diag-fmt.py; '..
          'echo; printf "press Enter to close... "; read -r _',
          file_found, file_found
        )}},
      }, pane
    )
    window:toast_notification('TurtleTerm', 'Diagnosing: ' .. file_found, nil, 2000)
  end)
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

-- Feature: CTRL+SHIFT+P — preview file (image via imgcat, code via bat/cat)
local function turtle_preview_file()
  return wezterm.action_callback(function(window, pane)
    -- 1. Try selection
    local path = ''
    local sel = window:get_selection_text_for_pane(pane)
    if sel and sel:match('^[%w_/%.%-~]+$') and #sel < 300 then
      path = sel:gsub('^%s+', ''):gsub('%s+$', '')
    end
    -- 2. Try input zone
    if path == '' then
      pcall(function()
        local zones = pane:get_semantic_zones()
        for _, z in ipairs(zones) do
          if z.semantic_type == 'Input' then
            local t = pane:get_text_from_semantic_zone(z)
            if t then path = t:gsub('^%s+', ''):gsub('%s+$', '') end
          end
        end
      end)
    end

    local image_exts = { png=1, jpg=1, jpeg=1, gif=1, bmp=1, webp=1, svg=1, tiff=1, tif=1, ico=1 }
    local ext = path:lower():match('%.([a-z]+)$') or ''

    if path == '' then
      -- 3. Prompt
      window:perform_action(act.PromptInputLine {
        description = '🐢 Preview file: enter path',
        action = wezterm.action_callback(function(w2, p2, line)
          if line and line ~= '' then
            local ext2 = line:lower():match('%.([a-z]+)$') or ''
            local is_img = image_exts[ext2] ~= nil
            w2:perform_action(act.SpawnCommandInNewPane {
              direction = 'Right', size = { Percent = 50 },
              command = { args = is_img
                and {'sh', '-c', 'imgcat ' .. line .. '; printf "\\npress Enter..."; read -r _'}
                or  {'sh', '-c', 'bat --paging=never ' .. line .. ' 2>/dev/null || cat ' .. line .. '; printf "\\npress Enter..."; read -r _'}
              },
            }, p2)
          end
        end),
      }, pane)
      return
    end

    local is_img = image_exts[ext] ~= nil
    window:perform_action(
      act.SpawnCommandInNewPane {
        direction = 'Right', size = { Percent = 50 },
        command = { args = is_img
          and {'sh', '-c', 'imgcat ' .. path .. ' 2>/dev/null; printf "\\npress Enter..."; read -r _'}
          or  {'sh', '-c', 'bat --paging=never ' .. path .. ' 2>/dev/null || cat ' .. path .. '; printf "\\npress Enter..."; read -r _'}
        },
      }, pane
    )
    window:toast_notification('TurtleTerm Preview', path, nil, 2000)
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
-- AI Sidebar (CTRL+SHIFT+X)
-- ============================================================

local function turtle_ai_sidebar()
  return wezterm.action_callback(function(window, pane)
    -- Check if AI sidebar pane is still alive
    local ai_pane_id = wezterm.GLOBAL.ai_sidebar_pane_id
    if ai_pane_id then
      local found = false
      local mux_win = window:mux_window()
      for _, p in ipairs(mux_win:panes()) do
        if p:pane_id() == ai_pane_id then
          found = true
          break
        end
      end
      if found then
        window:toast_notification('TurtleTerm AI', 'Sidebar already open — click to focus', nil, 2000)
        return
      end
    end
    -- Spawn the AI sidebar as a right split (35% width)
    local new_pane = pane:split {
      direction = 'Right',
      size = 0.35,
      command = { args = { 'turtle-ai-chat' } },
    }
    if new_pane then
      wezterm.GLOBAL.ai_sidebar_pane_id = new_pane:pane_id()
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
-- ============================================================
-- Command Palette (CMD+P)
-- Unified fuzzy launcher: named commands, recent shell history,
-- workflows, MCP tools. The discovery layer for everything.
-- ============================================================

local PALETTE_COMMANDS = {
  -- AI intelligence
  { label = '🤖  Explain selection          CTRL+SHIFT+E', id = 'explain_selection' },
  { label = '🤖  NL → shell command         CTRL+SHIFT+N', id = 'nl_to_shell' },
  { label = '🤖  AI complete current input  CTRL+SPACE',   id = 'ai_complete' },
  { label = '🤖  AI history search          CTRL+SHIFT+R', id = 'history_ai' },
  { label = '🤖  AI sidebar toggle          CTRL+SHIFT+X', id = 'ai_sidebar' },
  -- Planner
  { label = '⚡  Agent plan new goal        CTRL+SHIFT+M', id = 'plan_new' },
  { label = '⚡  Agent plan next step       CMD+SHIFT+N',  id = 'plan_next' },
  { label = '⚡  Agent plan view            —',             id = 'plan_view' },
  { label = '⚡  Agent plan abort           —',             id = 'plan_abort' },
  -- Blocks
  { label = '📋  Copy last output block     CMD+B',         id = 'block_copy_output' },
  { label = '📋  Copy last command          CMD+SHIFT+B',   id = 'block_copy_cmd' },
  { label = '📋  Explain last output block  CMD+SHIFT+E',   id = 'block_explain' },
  -- SynapseIQ
  { label = '⬡  Diagnose file (SynapseIQ)  CTRL+SHIFT+D', id = 'diagnose' },
  -- Navigation
  { label = '🔍  History fuzzy search       CTRL+R',        id = 'history_search' },
  { label = '🔍  Search output              CTRL+SHIFT+F',  id = 'search_output' },
  { label = '👁  Preview file (bat/imgcat)  CTRL+SHIFT+P',  id = 'preview' },
  { label = '🗺  Atlas context              CTRL+SHIFT+A',  id = 'atlas_context' },
  -- Workflows
  { label = '⚙   Browse workflows           CTRL+SHIFT+W', id = 'workflows' },
  -- Pane / tab
  { label = '⊞  Split pane right            CTRL+ALT+Enter', id = 'split_right' },
  { label = '⊟  Split pane down             CTRL+SHIFT+Enter', id = 'split_down' },
  { label = '＋  New tab                     CTRL+SHIFT+T', id = 'new_tab' },
  { label = '✕  Close pane                  CTRL+SHIFT+Q', id = 'close_pane' },
  -- Policy / security
  { label = '🛡  Policy gate                 CTRL+SHIFT+G', id = 'policy_gate' },
  -- Misc
  { label = '💾  Session note                CTRL+SHIFT+S', id = 'session_note' },
  { label = '🎨  Theme picker (400+ schemes) CTRL+SHIFT+I',  id = 'theme_picker' },
  -- Workspace
  { label = '💾  Save workspace              CMD+SHIFT+S',   id = 'workspace_save'    },
  { label = '📂  Restore workspace           CMD+SHIFT+O',   id = 'workspace_restore' },
}

local function turtle_command_palette()
  return wezterm.action_callback(function(window, pane)
    -- Build choice list: static commands + recent shell history
    local choices = {}
    for _, cmd in ipairs(PALETTE_COMMANDS) do
      table.insert(choices, { label = cmd.label, id = cmd.id })
    end

    -- Prepend recent commands from event stream (last 15)
    local home = os.getenv('HOME') or ''
    local stream_path = home .. '/.local/state/sourceos/terminal/events.ndjson'
    local f = io.open(stream_path, 'r')
    if f then
      local seen = {}
      local recent = {}
      for line in f:lines() do
        local ok2, evt = pcall(wezterm.json_parse, line)
        if ok2 and evt and evt.event_type == 'command.completed' and evt.command then
          local cmd = evt.command:gsub('^%s+', ''):gsub('%s+$', '')
          if cmd ~= '' and not seen[cmd] then
            seen[cmd] = true
            table.insert(recent, 1, { label = '⏱  ' .. cmd:sub(1, 80), id = 'run:' .. cmd })
          end
        end
      end
      f:close()
      for i = 1, math.min(15, #recent) do
        table.insert(choices, 1, recent[i])
      end
    end

    window:perform_action(
      act.InputSelector {
        action = wezterm.action_callback(function(w, p, id, label)
          if not id then return end
          -- Recent command: inject to prompt
          if id:sub(1, 4) == 'run:' then
            p:send_text(id:sub(5))
            return
          end
          -- Named commands
          local dispatch = {
            explain_selection  = turtle_explain_selection(),
            nl_to_shell        = turtle_nl_to_shell(),
            ai_complete        = turtle_ai_complete(),
            history_ai         = turtle_history_ai_search(),
            ai_sidebar         = turtle_ai_sidebar(),
            plan_new           = turtle_plan(),
            plan_next          = turtle_plan_next(),
            plan_view          = wezterm.action_callback(function(wi, pi)
              wi:perform_action(act.SpawnCommandInNewPane {
                direction = 'Right', size = { Percent = 38 },
                command = { args = { 'bash', '-c', 'turtle-plan-view --watch; read -r -p ""' } },
              }, pi)
            end),
            plan_abort         = wezterm.action_callback(function(wi, _pi)
              wezterm.run_child_process({ 'turtle-agentctl', '--stdio', 'plan-abort' })
              wi:toast_notification('TurtleTerm', 'Plan aborted', nil, 2000)
            end),
            block_copy_output  = act.CopyTo 'ClipboardAndPrimarySelection',
            block_copy_cmd     = act.CopyTo 'ClipboardAndPrimarySelection',
            block_explain      = turtle_block_explain_last(),
            diagnose           = turtle_diagnose(),
            history_search     = turtle_history_search(),
            search_output      = act.Search 'CurrentSelectionOrEmptyString',
            preview            = turtle_preview_file(),
            atlas_context      = turtle_atlas_context(),
            workflows          = turtle_workflows(),
            split_right        = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
            split_down         = act.SplitVertical { domain = 'CurrentPaneDomain' },
            new_tab            = act.SpawnTab 'CurrentPaneDomain',
            close_pane         = act.CloseCurrentPane { confirm = true },
            policy_gate        = turtle_policy_gate(),
            session_note       = act.PromptInputLine {
              description = 'TurtleTerm session note',
              action = wezterm.action_callback(function(wi, _pi, line)
                if line and line ~= '' then wezterm.log_info('session_note: ' .. line) end
              end),
            },
            theme_picker       = turtle_theme_picker(),
            workspace_save     = turtle_workspace_save(),
            workspace_restore  = turtle_workspace_restore(),
          }
          local a = dispatch[id]
          if a then w:perform_action(a, p) end
        end),
        title = 'TurtleTerm  ⌘P',
        choices = choices,
        fuzzy = true,
        fuzzy_description = 'Search commands, AI actions, recent history…',
      },
      pane
    )
  end)
end

-- ============================================================
-- Semantic block: explain last output (CMD+SHIFT+E)
-- ============================================================

local function turtle_block_explain_last()
  return wezterm.action_callback(function(window, pane)
    local zones = {}
    pcall(function() zones = pane:get_semantic_zones() end)
    local last_output = nil
    for _, z in ipairs(zones) do
      if z.semantic_type == 'Output' then last_output = z end
    end
    if not last_output then
      window:toast_notification('TurtleTerm', 'No output block found — run a command first.', nil, 3000)
      return
    end
    local text = ''
    pcall(function() text = pane:get_text_from_semantic_zone(last_output) end)
    text = text:gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then
      window:toast_notification('TurtleTerm', 'Output block is empty.', nil, 3000)
      return
    end
    -- Write to temp file and open explain split
    local tmp = '/tmp/turtle-explain-sel.txt'
    local f = io.open(tmp, 'w')
    if f then f:write(text); f:close() end
    window:perform_action(
      act.SpawnCommandInNewPane {
        direction = 'Right',
        size = { Percent = 40 },
        command = { args = { 'sh', '-c',
          'clear; echo "=== Explain: last output block ==="; echo; '
          .. "sel=$(cat /tmp/turtle-explain-sel.txt); "
          .. "turtle-agentctl explain-selection \"$sel\" 2>/dev/null "
          .. "| python3 -c \"import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('explanation','(no response)'))\" "
          .. '2>/dev/null || echo "(could not reach AI)"; '
          .. 'echo; printf "press Enter to close "; read -r _',
        } },
      },
      pane
    )
  end)
end

-- ============================================================
-- Agent Planner Loop (CTRL+SHIFT+M — "Mission")
-- Asks for a goal, calls turtle-agentctl plan <goal>,
-- injects step 1 into the terminal prompt, opens a plan
-- viewer in a right split so the user can see all steps.
-- ============================================================

local function turtle_plan()
  return wezterm.action_callback(function(window, pane)
    window:perform_action(
      act.PromptInputLine {
        description = 'TurtleTerm Agent Plan — describe your goal:',
        action = wezterm.action_callback(function(w, p, goal)
          if not goal or goal == '' then return end
          -- Run plan generation + viewer in a right split
          -- turtle-plan-view --watch auto-refreshes every 2s and exits when done
          w:perform_action(
            act.SplitPane {
              direction = 'Right',
              size = { Percent = 38 },
              command = { args = {
                'bash', '-c',
                'echo "  Planning…" && turtle-agentctl --stdio plan "$@" > /dev/null 2>&1'
                .. ' && turtle-plan-view --watch'
                .. ' ; echo ""; read -r -p "Press Enter to close "',
                '--', goal,
              } },
            },
            p
          )
          w:toast_notification('TurtleTerm Planner', 'Planning: ' .. goal, nil, 3000)
        end),
      },
      pane
    )
  end)
end

-- plan-next: advance to next plan step (CTRL+SHIFT+N)
local function turtle_plan_next()
  return wezterm.action_callback(function(window, pane)
    local result = turtle_agentctl_json({ 'plan-next' })
    if result and result.status == 'ok' then
      local d = result.data or {}
      if d.status == 'all_steps_complete' then
        window:toast_notification('TurtleTerm Planner', '✓ Plan complete: ' .. (d.goal or ''), nil, 4000)
      elseif d.command and d.command ~= '' then
        pane:send_text(d.command)
        window:toast_notification(
          'TurtleTerm Planner',
          string.format('Step %d/%d: %s', (d.step or 0) + 1, d.step_count or 1, d.description or d.command),
          nil, 4000
        )
      end
    else
      window:toast_notification('TurtleTerm Planner', 'No active plan — use CTRL+SHIFT+M to start one', nil, 3000)
    end
  end)
end

-- ============================================================
-- Theme picker (CTRL+SHIFT+T → pick, live preview, Enter to keep)
-- Uses WezTerm's built-in color scheme library (400+ schemes).
-- ============================================================

local _current_scheme = nil  -- tracks live-preview scheme so Escape can revert

local function turtle_theme_picker()
  return wezterm.action_callback(function(window, pane)
    local original = window:effective_config().color_scheme or 'TurtleTerm Dark'
    _current_scheme = original

    -- Build scheme list: put current scheme first, then alphabetical
    local all = {}
    for name, _ in pairs(wezterm.color.get_builtin_color_schemes()) do
      table.insert(all, name)
    end
    table.sort(all)

    local choices = {}
    -- Current scheme at top for easy escape
    table.insert(choices, { label = '● ' .. original .. '  (current)', id = original })
    for _, name in ipairs(all) do
      if name ~= original then
        table.insert(choices, { label = name, id = name })
      end
    end

    window:perform_action(
      act.InputSelector {
        action = wezterm.action_callback(function(w, _p, id, _label)
          if id then
            -- User confirmed a selection — apply permanently for this session
            w:set_config_overrides({ color_scheme = id })
            _current_scheme = id
            w:toast_notification('TurtleTerm Theme', id, nil, 2500)
          else
            -- Escape pressed — revert to original
            w:set_config_overrides({ color_scheme = original })
          end
        end),
        title = 'TurtleTerm  Theme Picker',
        choices = choices,
        fuzzy = true,
        fuzzy_description = 'Type to filter 400+ schemes…',
      },
      pane
    )
  end)
end

-- ============================================================
-- Semantic block context menu (right-click)
-- Reads Output/Input zones, offers copy/explain/rerun/save.
-- Falls back to paste if no zones are found.
-- ============================================================

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function clipboard_write(text)
  local f = io.popen('pbcopy 2>/dev/null || xclip -selection clipboard 2>/dev/null || wl-copy 2>/dev/null', 'w')
  if f then f:write(text); f:close() end
end

local function turtle_block_context_menu()
  return wezterm.action_callback(function(window, pane)
    local zones = {}
    pcall(function() zones = pane:get_semantic_zones() end)

    local last_output, last_input = nil, nil
    for _, z in ipairs(zones) do
      if z.semantic_type == 'Output' then last_output = z end
      if z.semantic_type == 'Input'  then last_input  = z end
    end

    local choices = {}
    if last_output then
      table.insert(choices, { label = '📋  Copy last output block',   id = 'copy_output'   })
      table.insert(choices, { label = '🤖  Explain last output (AI)', id = 'explain_output' })
      table.insert(choices, { label = '💾  Save block to file',       id = 'save_block'    })
    end
    if last_input then
      table.insert(choices, { label = '↩   Re-run last command',      id = 'rerun'         })
      table.insert(choices, { label = '📋  Copy last command',        id = 'copy_cmd'      })
    end
    table.insert(choices, { label = '📋  Copy selection',    id = 'copy_sel' })
    table.insert(choices, { label = '🔍  Search in output',  id = 'search'   })
    table.insert(choices, { label = '⌨   Paste from clipboard', id = 'paste' })

    -- If no semantic zones yet, just paste (typical right-click behavior)
    if not last_output and not last_input then
      window:perform_action(act.PasteFrom 'Clipboard', pane)
      return
    end

    window:perform_action(
      act.InputSelector {
        action = wezterm.action_callback(function(w, p, id, _label)
          if not id then return end
          if id == 'copy_output' then
            local text = ''
            pcall(function() text = p:get_text_from_semantic_zone(last_output) end)
            clipboard_write(text)
            w:toast_notification('TurtleTerm', string.format('Copied %d chars', #text), nil, 2000)

          elseif id == 'explain_output' then
            w:perform_action(turtle_block_explain_last(), p)

          elseif id == 'save_block' then
            local text = ''
            pcall(function() text = p:get_text_from_semantic_zone(last_output) end)
            local home = os.getenv('HOME') or ''
            local dir = home .. '/.local/share/turtleterm/blocks'
            os.execute('mkdir -p ' .. shell_quote(dir))
            local fname = dir .. '/block-' .. os.date('%Y%m%d-%H%M%S') .. '.txt'
            local f = io.open(fname, 'w')
            if f then f:write(text); f:close()
              w:toast_notification('TurtleTerm', 'Saved: ' .. fname, nil, 3000)
            end

          elseif id == 'rerun' then
            local text = ''
            pcall(function() text = p:get_text_from_semantic_zone(last_input) end)
            text = text:gsub('^%s+', ''):gsub('%s+$', '')
            if text ~= '' then p:send_text(text .. '\n') end

          elseif id == 'copy_cmd' then
            local text = ''
            pcall(function() text = p:get_text_from_semantic_zone(last_input) end)
            clipboard_write(text:gsub('^%s+', ''):gsub('%s+$', ''))

          elseif id == 'copy_sel' then
            w:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', p)

          elseif id == 'search' then
            w:perform_action(act.Search 'CurrentSelectionOrEmptyString', p)

          elseif id == 'paste' then
            w:perform_action(act.PasteFrom 'Clipboard', p)
          end
        end),
        title = 'TurtleTerm  Block Actions',
        choices = choices,
        fuzzy = true,
      },
      pane
    )
  end)
end

-- Wire right-click to the context menu (must follow turtle_block_context_menu definition)
table.insert(config.mouse_bindings, {
  event  = { Up = { streak = 1, button = 'Right' } },
  mods   = 'NONE',
  action = wezterm.action_callback(function(window, pane)
    window:perform_action(turtle_block_context_menu(), pane)
  end),
})

-- ============================================================
-- Workspace save / restore (CMD+SHIFT+S / CMD+SHIFT+O)
-- Serializes tab layout, pane cwds, and tab titles to JSON.
-- Restore recreates tabs and panes, cds each to saved dir.
-- ============================================================

local WS_DIR = (os.getenv('HOME') or '') .. '/.config/turtleterm/workspaces'

local function turtle_workspace_save()
  return wezterm.action_callback(function(window, pane)
    window:perform_action(
      act.PromptInputLine {
        description = 'Save workspace as (name):',
        action = wezterm.action_callback(function(w, _p, name)
          if not name or name:match('^%s*$') then return end
          name = name:gsub('[^%w%-_]', '_')  -- sanitize

          local tabs_data = {}
          for _, tab in ipairs(w:tabs()) do
            local panes_data = {}
            local ok2, panes_info = pcall(function() return tab:panes_with_info() end)
            if ok2 and panes_info then
              for _, pi in ipairs(panes_info) do
                local cwd = ''
                local ok3, cwdurl = pcall(function() return pi.pane:get_current_working_dir() end)
                if ok3 and cwdurl then
                  cwd = tostring(cwdurl):gsub('^file://[^/]*', '')
                end
                local proc = ''
                pcall(function() proc = pi.pane:get_foreground_process_name() or '' end)
                table.insert(panes_data, {
                  cwd   = cwd,
                  proc  = proc:match('[^/\\]+$') or proc,  -- basename
                  left  = pi.left,  top    = pi.top,
                  width = pi.width, height = pi.height,
                  is_active = pi.is_active,
                })
              end
            end
            table.insert(tabs_data, {
              title = tab:get_title() or '',
              panes = panes_data,
            })
          end

          local ws = {
            name     = name,
            saved_at = os.date('%Y-%m-%dT%H:%M:%S'),
            tabs     = tabs_data,
          }

          os.execute('mkdir -p ' .. shell_quote(WS_DIR))
          local path = WS_DIR .. '/' .. name .. '.json'
          local f = io.open(path, 'w')
          if f then
            f:write(wezterm.json_encode(ws))
            f:close()
            -- Track last saved workspace for startup auto-restore offer
            local lf2 = io.open(WS_DIR .. '/_last.txt', 'w')
            if lf2 then lf2:write(name); lf2:close() end
            w:toast_notification('TurtleTerm Workspace', 'Saved: ' .. name
              .. ' (' .. #tabs_data .. ' tabs)', nil, 3000)
          else
            w:toast_notification('TurtleTerm Workspace', 'ERROR: could not write ' .. path, nil, 4000)
          end
        end),
      },
      pane
    )
  end)
end

local function turtle_workspace_restore()
  return wezterm.action_callback(function(window, pane)
    -- List saved workspaces
    local choices = {}
    local ok2, stdout, _ = wezterm.run_child_process({ 'ls', WS_DIR })
    if ok2 and stdout then
      for fname in stdout:gmatch('[^\n]+') do
        local name = fname:match('^(.+)%.json$')
        if name then
          table.insert(choices, { label = '📁  ' .. name, id = name })
        end
      end
    end

    if #choices == 0 then
      window:toast_notification('TurtleTerm Workspace', 'No saved workspaces — use CMD+SHIFT+S to save one.', nil, 4000)
      return
    end

    window:perform_action(
      act.InputSelector {
        action = wezterm.action_callback(function(w, p, id, _label)
          if not id then return end
          local path = WS_DIR .. '/' .. id .. '.json'
          local f = io.open(path, 'r')
          if not f then
            w:toast_notification('TurtleTerm', 'Workspace not found: ' .. id, nil, 3000)
            return
          end
          local raw = f:read('*a'); f:close()
          local ok3, ws = pcall(wezterm.json_parse, raw)
          if not ok3 or not ws then
            w:toast_notification('TurtleTerm', 'Could not parse workspace: ' .. id, nil, 3000)
            return
          end

          local tabs = ws.tabs or {}
          local restored = 0

          for ti, tab_data in ipairs(tabs) do
            local panes_data = tab_data.panes or {}
            if #panes_data == 0 then goto next_tab end

            local cur_tab, first_pane
            if ti == 1 then
              -- Reuse current tab
              cur_tab   = w:active_tab()
              first_pane = w:active_pane()
            else
              -- Spawn a new tab
              local ok4
              ok4, cur_tab, first_pane = pcall(function()
                return w:spawn_tab({})
              end)
              if not ok4 then goto next_tab end
            end

            -- CD first pane
            local first_cwd = panes_data[1] and panes_data[1].cwd or ''
            if first_cwd ~= '' then
              first_pane:send_text('cd ' .. shell_quote(first_cwd) .. '\n')
            end

            -- Reconstruct additional panes with approximate splits
            -- Strategy: alternate Right/Bottom based on relative position
            local prev = first_pane
            for pi = 2, #panes_data do
              local pd = panes_data[pi]
              local prev_pd = panes_data[pi - 1]
              -- If top changed significantly → split bottom; else split right
              local direction = 'Right'
              if prev_pd and pd.top and prev_pd.top and
                 (pd.top - prev_pd.top) > (pd.left or 0) - (prev_pd.left or 0) then
                direction = 'Bottom'
              end
              local new_pane
              pcall(function()
                new_pane = prev:split({ direction = direction, size = 1 / (#panes_data - pi + 2) })
              end)
              if new_pane and pd.cwd and pd.cwd ~= '' then
                new_pane:send_text('cd ' .. shell_quote(pd.cwd) .. '\n')
              end
              if new_pane then prev = new_pane end
            end

            restored = restored + 1
            ::next_tab::
          end

          w:toast_notification('TurtleTerm Workspace', 'Restored: ' .. id
            .. ' (' .. restored .. '/' .. #tabs .. ' tabs)', nil, 3000)
        end),
        title = 'TurtleTerm  Restore Workspace',
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

  -- Command palette — discovery layer for everything
  { key = 'p', mods = 'CMD',           action = turtle_command_palette() },  -- CMD+P palette

  -- Agent intelligence
  { key = 'e', mods = 'CTRL|SHIFT',   action = turtle_explain_selection() },
  { key = 'e', mods = 'CMD|SHIFT',    action = turtle_block_explain_last() }, -- Explain last output block
  { key = 'n', mods = 'CTRL|SHIFT',   action = turtle_nl_to_shell() },
  { key = 'a', mods = 'CTRL|SHIFT',   action = turtle_atlas_context() },
  { key = 'd', mods = 'CTRL|SHIFT',   action = turtle_diagnose() },          -- SynapseIQ diagnose
  { key = 'Space', mods = 'CTRL',     action = turtle_ai_complete() },       -- AI ghost-text (explicit)
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
  { key = 'x', mods = 'CTRL|SHIFT', action = turtle_ai_sidebar() },  -- AI sidebar toggle
  { key = 'p', mods = 'CTRL|SHIFT', action = turtle_preview_file() },
  { key = 'o', mods = 'CTRL|SHIFT', action = act.ShowLauncher },
  { key = 'g', mods = 'CTRL|SHIFT', action = turtle_policy_gate() },
  { key = 'm', mods = 'CTRL|SHIFT', action = turtle_plan() },         -- Agent planner: set a goal
  { key = 'n', mods = 'CMD|SHIFT',  action = turtle_plan_next() },    -- Advance to next plan step
  { key = 'i', mods = 'CTRL|SHIFT', action = turtle_theme_picker() }, -- Theme picker (i = interface)
  { key = 's', mods = 'CMD|SHIFT',  action = turtle_workspace_save()    },  -- Save workspace
  { key = 'o', mods = 'CMD|SHIFT',  action = turtle_workspace_restore() },  -- Restore workspace
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
  local proc = ''
  pcall(function() proc = pane:get_foreground_process_name() or '' end)
  local cwd_uri = ''
  pcall(function() cwd_uri = tostring(pane.current_working_dir) or '' end)
  local is_ssh = proc:find('ssh') ~= nil or cwd_uri:find('^ssh://') ~= nil

  -- Plan step indicator: show ⚡ goal [step/total] when a plan is active
  local plan_badge = ''
  do
    local home = os.getenv('HOME') or ''
    local plan_path = home .. '/.local/state/sourceos/terminal/current_plan.json'
    local pf = io.open(plan_path, 'r')
    if pf then
      local raw = pf:read('*a'); pf:close()
      local ok2, plan = pcall(wezterm.json_parse, raw)
      if ok2 and plan and plan.steps then
        local step = (plan.current_step or 0) + 1
        local total = #plan.steps
        local goal = (plan.goal or ''):sub(1, 30)
        if step <= total then
          plan_badge = string.format('  \xe2\x9a\xa1 %s [%d/%d]  ', goal, step, total)
        end
      end
    end
  end

  if is_ssh then
    window:set_right_status(plan_badge .. '  \xe2\x87\x84 ssh  ')  -- ⇄ ssh
    -- Red title bar tint while inside SSH session
    local overrides = window:get_config_overrides() or {}
    if not overrides._ssh_frame then
      overrides._ssh_frame = true
      overrides.window_frame = {
        active_titlebar_bg   = '#3a0000',
        inactive_titlebar_bg = '#290000',
        active_titlebar_fg   = '#ffaaaa',
        inactive_titlebar_fg = '#cc7777',
        border_left_width    = '0.5cell',
        border_right_width   = '0.5cell',
        border_bottom_height = '0.25cell',
        border_top_height    = '0.25cell',
        border_left_color    = '#5a0000',
        border_right_color   = '#5a0000',
        border_bottom_color  = '#5a0000',
        border_top_color     = '#5a0000',
      }
      window:set_config_overrides(overrides)
    end
  else
    -- Clear SSH frame override when we leave SSH
    local overrides = window:get_config_overrides() or {}
    if overrides._ssh_frame then
      overrides._ssh_frame = nil
      overrides.window_frame = nil
      window:set_config_overrides(overrides)
    end
    if domain ~= 'host' then
      window:set_right_status(plan_badge .. string.format('  %s  ', domain))
    else
      window:set_right_status(plan_badge)
    end
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

  -- Workspace restore offer (fires once on startup if a saved workspace exists)
  if wezterm.GLOBAL._ws_restore_name then
    local name = wezterm.GLOBAL._ws_restore_name
    wezterm.GLOBAL._ws_restore_name = nil
    window:toast_notification(
      'TurtleTerm Workspace',
      'Last session: "' .. name .. '" — press CMD+SHIFT+O to restore',
      nil, 7000
    )
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

  -- Plan auto-advance: when a plan step ran and exited cleanly, auto-call plan_next.
  -- Set by the pending_command injection below when source == "plan".
  -- Opt out: TURTLE_PLAN_AUTO_ADVANCE=0
  if exit_content ~= (wezterm.GLOBAL.last_plan_exit or '') and wezterm.GLOBAL._turtle_plan_waiting then
    local plan_exit_num = tonumber(exit_content) or -1
    -- Only act when exit code actually settled (non-empty)
    if exit_content ~= '' then
      wezterm.GLOBAL._turtle_plan_waiting = nil
      wezterm.GLOBAL.last_plan_exit = exit_content
      local auto_advance = os.getenv('TURTLE_PLAN_AUTO_ADVANCE') ~= '0'
      if plan_exit_num == 0 and auto_advance then
        -- Clean exit → advance to next step silently then toast result
        local ok2, out2, _ = wezterm.run_child_process({
          'turtle-agentctl', '--stdio', 'plan-next'
        })
        if ok2 and out2 then
          local ok3, resp = pcall(wezterm.json_parse, out2)
          if ok3 and resp then
            if resp.kind == 'plan_complete' then
              window:toast_notification('TurtleTerm Plan', '✓ Plan complete! Goal achieved.', nil, 4000)
            else
              local step = resp.data and resp.data.step or '?'
              local total = resp.data and resp.data.step_count or '?'
              local desc = resp.data and resp.data.description or ''
              window:toast_notification('TurtleTerm Plan',
                string.format('Step %s/%s ready → %s', step + 1, total, desc:sub(1, 60)), nil, 4000)
            end
          end
        end
      elseif plan_exit_num ~= 0 then
        -- Failed step — pause and notify
        window:toast_notification('TurtleTerm Plan',
          string.format('Step failed (exit %d) — check output, then CMD+SHIFT+N to continue or CMD+P → plan abort',
            plan_exit_num), nil, 7000)
      end
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

  -- Pending command injection (from plan_execute / terminal_execute_with_confirmation)
  local pending_path = xdg_state .. '/sourceos/terminal/pending_command'
  local pf = io.open(pending_path, 'r')
  if pf then
    local cmd_text = pf:read('*a')
    pf:close()
    os.remove(pending_path)
    if cmd_text and cmd_text ~= '' then
      cmd_text = cmd_text:match('^%s*(.-)%s*$')  -- trim

      -- Read metadata to detect plan source and arm auto-advance
      local meta_path = xdg_state .. '/sourceos/terminal/pending_command.json'
      local mf = io.open(meta_path, 'r')
      local is_plan_step = false
      if mf then
        local raw = mf:read('*a'); mf:close()
        os.remove(meta_path)
        local ok2, meta = pcall(wezterm.json_parse, raw)
        if ok2 and meta and meta.source == 'plan' then
          is_plan_step = true
          local step = (meta.plan_step or 0) + 1
          local total = meta.plan_total or '?'
          local desc  = meta.description or ''
          local goal  = meta.goal or ''
          -- Arm auto-advance: will fire when exit code edge arrives
          wezterm.GLOBAL._turtle_plan_waiting = true
          wezterm.GLOBAL.last_plan_exit = exit_content  -- snapshot current
          window:toast_notification(
            string.format('TurtleTerm Plan  [%s/%s]', step, total),
            string.format('%s\n$ %s', desc:sub(1,80), cmd_text:sub(1,60)),
            nil, 5000
          )
        end
      end

      pane:send_text(cmd_text)
      if not is_plan_step then
        window:toast_notification('TurtleTerm Agent', 'Command ready (press Enter): ' .. cmd_text:sub(1, 60), nil, 4000)
      end
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
  -- Auto-start SynapseIQ LSP server in background (no-op if already running)
  io.popen('turtle-synapseiq start >/dev/null 2>&1 &')

  -- Workspace auto-restore: if a 'default' workspace was saved, offer to restore it.
  -- Check for a startup-restore sentinel to avoid repeating on every reload.
  if not wezterm.GLOBAL._ws_restore_offered then
    wezterm.GLOBAL._ws_restore_offered = true
    local ws_dir = (os.getenv('HOME') or '') .. '/.config/turtleterm/workspaces'
    local last_file = ws_dir .. '/_last.txt'
    local lf = io.open(last_file, 'r')
    if lf then
      local last_name = lf:read('*l'); lf:close()
      if last_name and last_name ~= '' then
        local ws_path = ws_dir .. '/' .. last_name .. '.json'
        local wf = io.open(ws_path, 'r')
        if wf then wf:close()
          -- Schedule the toast+restore offer via the global so update-left-status can pick it up
          wezterm.GLOBAL._ws_restore_name = last_name
        end
      end
    end
  end
end)

return config
