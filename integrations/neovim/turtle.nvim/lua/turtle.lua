local M = {}

local function agentctl_args(...)
  local args = { 'turtle-agentctl', '--stdio' }
  for _, value in ipairs({ ... }) do
    if value ~= nil and value ~= '' then
      table.insert(args, value)
    end
  end
  return args
end

local function notify_payload(title, payload)
  local text = vim.fn.json_encode(payload)
  vim.notify(title .. '\n' .. text, vim.log.levels.INFO)
end

local function run_command(title, args)
  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify(title .. ' failed\n' .. (result.stderr or result.stdout or ''), vim.log.levels.ERROR)
        return
      end
      local ok, payload = pcall(vim.json.decode, result.stdout)
      if ok then
        notify_payload(title, payload)
      else
        vim.notify(title .. '\n' .. result.stdout, vim.log.levels.INFO)
      end
    end)
  end)
end

local function run_agentctl(title, ...)
  run_command(title, agentctl_args(...))
end

local function run_language(title, ...)
  local args = { 'turtle-language' }
  for _, value in ipairs({ ... }) do
    if value ~= nil and value ~= '' then
      table.insert(args, value)
    end
  end
  run_command(title, args)
end

local function run_session(title, ...)
  local args = { 'turtle-session' }
  for _, value in ipairs({ ... }) do
    if value ~= nil and value ~= '' then
      table.insert(args, value)
    end
  end
  run_command(title, args)
end

local function join_args(values)
  if type(values) == 'table' then
    return table.concat(values, ' ')
  end
  return values
end

local function current_file_or(value)
  if value ~= nil and value ~= '' then
    return value
  end
  local name = vim.api.nvim_buf_get_name(0)
  if name == nil or name == '' then
    vim.notify('Current buffer has no file path', vim.log.levels.ERROR)
    return nil
  end
  return name
end

function M.ping()
  run_agentctl('TurtleTerm ping', 'ping')
end

function M.sessions()
  run_agentctl('TurtleTerm sessions', 'sessions')
end

function M.profiles()
  run_session('TurtleTerm profiles', 'profiles')
end

function M.layout_export()
  run_session('TurtleTerm layout export', 'layout-export')
end

function M.marks()
  run_session('TurtleTerm marks', 'marks')
end

function M.mark(text)
  if text == nil or text == '' then
    text = 'operator mark'
  end
  run_session('TurtleTerm mark', 'mark', text)
end

function M.search(query)
  if query == nil or query == '' then
    vim.notify('TurtleSearch requires a query', vim.log.levels.ERROR)
    return
  end
  run_session('TurtleTerm search', 'search', query)
end

function M.replay_plan()
  run_session('TurtleTerm replay plan', 'replay-plan')
end

function M.surfaces()
  run_agentctl('TurtleTerm surfaces', 'surfaces')
end

function M.inspect_surface(surface_id)
  run_agentctl('TurtleTerm inspect surface', 'inspect-surface', surface_id)
end

function M.request_surface_execution(values)
  if values == nil or #values < 2 then
    vim.notify('TurtleSurfaceRequestExecution requires <surface> <command>', vim.log.levels.ERROR)
    return
  end
  local surface = values[1]
  table.remove(values, 1)
  run_agentctl('TurtleTerm request surface execution', 'request-surface-execution', surface, join_args(values))
end

function M.diagnostics(file)
  file = current_file_or(file)
  if file then
    run_language('TurtleTerm diagnostics', 'diagnostics', file)
  end
end

function M.symbols(file)
  file = current_file_or(file)
  if file then
    run_language('TurtleTerm symbols', 'symbols', file)
  end
end

function M.explain_selection()
  local file = current_file_or('')
  if not file then
    return
  end
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  if start_line == 0 or end_line == 0 then
    start_line = vim.fn.line('.')
    end_line = start_line
  end
  run_language('TurtleTerm explain selection', 'explain-selection', file, '--start', tostring(start_line), '--end', tostring(end_line))
end

function M.propose_patch(prompt)
  local file = current_file_or('')
  if not file then
    return
  end
  if prompt == nil or prompt == '' then
    prompt = 'propose safe patch'
  end
  run_language('TurtleTerm propose patch', 'propose-patch', file, '--prompt', prompt)
end

function M.index(root)
  if root == nil or root == '' then
    root = vim.fn.getcwd()
  end
  run_language('TurtleTerm index', 'index', root)
end

function M.cloudfog_surfaces()
  run_agentctl('TurtleTerm CloudFog surfaces', 'cloudfog-surfaces')
end

function M.cloudfog_inspect(surface_id)
  run_agentctl('TurtleTerm CloudFog inspect', 'cloudfog-inspect', surface_id)
end

function M.superconscious_observe(text)
  -- Include current file and cursor position as buffer context.
  local file = vim.api.nvim_buf_get_name(0)
  local line = vim.fn.line('.')
  local col = vim.fn.col('.')
  local ctx = ''
  if file ~= nil and file ~= '' then
    ctx = ' [file:' .. file .. ' line:' .. tostring(line) .. ' col:' .. tostring(col) .. ']'
  end
  local observation = (text ~= nil and text ~= '') and (text .. ctx) or ('buffer-context' .. ctx)
  run_agentctl('TurtleTerm Superconscious observe', 'superconscious-observe', observation)
end

function M.superconscious_propose(prompt)
  run_agentctl('TurtleTerm Superconscious propose', 'superconscious-propose', prompt)
end

function M.noetica_status()
  run_agentctl('TurtleTerm Noetica status', 'noetica-status')
end

function M.noetica_query(text)
  if text == nil or text == '' then
    vim.notify('TurtleNoeticaQuery requires a query', vim.log.levels.ERROR)
    return
  end
  run_agentctl('TurtleTerm Noetica query', 'noetica-query', text)
end

function M.policy_status()
  run_agentctl('TurtleTerm Policy status', 'policy-status')
end

function M.hover(file, line, character)
  file = current_file_or(file)
  if not file then return end
  line = line or vim.fn.line('.')
  character = character or vim.fn.col('.')
  run_language('TurtleTerm hover', 'hover', file, '--line', tostring(line), '--character', tostring(character))
end

function M.synapseiq_status()
  run_language('TurtleTerm SynapseIQ status', 'synapseiq-status')
end

function M.synapseiq_lsp_snippet()
  local lines = {
    'Add to your Neovim config (requires nvim-lspconfig):',
    '',
    '  local lspconfig = require("lspconfig")',
    '  local configs = require("lspconfig.configs")',
    '',
    '  if not configs.synapseiq then',
    '    configs.synapseiq = {',
    '      default_config = {',
    '        cmd = { "synapseiq-lsp" },',
    '        filetypes = {',
    '          "python", "typescript", "javascript",',
    '          "lua", "rust", "go", "sh", "json", "yaml",',
    '          "ruby", "java", "cpp", "c",',
    '        },',
    '        root_dir = lspconfig.util.root_pattern(".git", "."),',
    '        single_file_support = true,',
    '        settings = {},',
    '      },',
    '    }',
    '  end',
    '  lspconfig.synapseiq.setup({})',
    '',
    'Or with vim.lsp.start (no lspconfig dependency):',
    '',
    '  vim.api.nvim_create_autocmd("FileType", {',
    '    pattern = { "python","typescript","javascript","lua","rust","go" },',
    '    callback = function(ev)',
    '      vim.lsp.start({',
    '        name = "synapseiq-lsp",',
    '        cmd = { "synapseiq-lsp" },',
    '        root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),',
    '      })',
    '    end,',
    '  })',
  }
  -- Print to messages as a fallback; callers can use s:show_float via the .vim plugin
  for _, line in ipairs(lines) do
    vim.notify(line, vim.log.levels.INFO)
  end
end

function M.agent_machine_surfaces()
  run_agentctl('TurtleTerm Agent Machine surfaces', 'agent-machine-surfaces')
end

function M.agent_machine_probe()
  run_agentctl('TurtleTerm Agent Machine probe', 'agent-machine-probe')
end

function M.bearbrowser_handoff(task)
  if task == nil or task == '' then
    vim.notify('TurtleBearBrowserHandoff requires a task description', vim.log.levels.ERROR)
    return
  end
  run_agentctl('TurtleTerm BearBrowser handoff', 'bearbrowser-handoff', task)
end

function M.inspect(session_id)
  run_agentctl('TurtleTerm inspect', 'inspect', session_id)
end

function M.summarize(session_id)
  run_agentctl('TurtleTerm summarize', 'summarize', session_id)
end

function M.propose(command)
  if command == nil or command == '' then
    vim.notify('TurtlePropose requires a command', vim.log.levels.ERROR)
    return
  end
  run_agentctl('TurtleTerm propose', 'propose', command)
end

function M.request_execution(command)
  if command == nil or command == '' then
    vim.notify('TurtleRequestExecution requires a command', vim.log.levels.ERROR)
    return
  end
  run_agentctl('TurtleTerm request execution', 'request-execution', command)
end

function M.receipts(session_id)
  run_agentctl('TurtleTerm receipts', 'receipts', session_id)
end

return M
