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

local function run_agentctl(title, ...)
  local args = agentctl_args(...)
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

function M.ping()
  run_agentctl('TurtleTerm ping', 'ping')
end

function M.sessions()
  run_agentctl('TurtleTerm sessions', 'sessions')
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
