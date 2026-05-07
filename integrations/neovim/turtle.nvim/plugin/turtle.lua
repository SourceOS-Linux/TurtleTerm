if vim.g.loaded_turtle_nvim == 1 then
  return
end
vim.g.loaded_turtle_nvim = 1

local turtle = require('turtle')

vim.api.nvim_create_user_command('TurtlePing', function()
  turtle.ping()
end, {})

vim.api.nvim_create_user_command('TurtleSessions', function()
  turtle.sessions()
end, {})

vim.api.nvim_create_user_command('TurtleSurfaces', function()
  turtle.surfaces()
end, {})

vim.api.nvim_create_user_command('TurtleInspectSurface', function(opts)
  turtle.inspect_surface(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command('TurtleSurfaceRequestExecution', function(opts)
  turtle.request_surface_execution(opts.fargs)
end, { nargs = '+' })

vim.api.nvim_create_user_command('TurtleDiagnostics', function(opts)
  turtle.diagnostics(opts.args)
end, { nargs = '?' })

vim.api.nvim_create_user_command('TurtleSymbols', function(opts)
  turtle.symbols(opts.args)
end, { nargs = '?' })

vim.api.nvim_create_user_command('TurtleExplainSelection', function()
  turtle.explain_selection()
end, { range = true })

vim.api.nvim_create_user_command('TurtleProposePatch', function(opts)
  turtle.propose_patch(opts.args)
end, { nargs = '*' })

vim.api.nvim_create_user_command('TurtleIndex', function(opts)
  turtle.index(opts.args)
end, { nargs = '?' })

vim.api.nvim_create_user_command('TurtleCloudFogSurfaces', function()
  turtle.cloudfog_surfaces()
end, {})

vim.api.nvim_create_user_command('TurtleCloudFogInspect', function(opts)
  turtle.cloudfog_inspect(opts.args)
end, { nargs = '?' })

vim.api.nvim_create_user_command('TurtleSuperconsciousObserve', function(opts)
  turtle.superconscious_observe(opts.args)
end, { nargs = '*' })

vim.api.nvim_create_user_command('TurtleSuperconsciousPropose', function(opts)
  turtle.superconscious_propose(opts.args)
end, { nargs = '*' })

vim.api.nvim_create_user_command('TurtleAgentMachineSurfaces', function()
  turtle.agent_machine_surfaces()
end, {})

vim.api.nvim_create_user_command('TurtleAgentMachineProbe', function()
  turtle.agent_machine_probe()
end, {})

vim.api.nvim_create_user_command('TurtleInspect', function(opts)
  turtle.inspect(opts.args)
end, { nargs = '?' })

vim.api.nvim_create_user_command('TurtleSummarize', function(opts)
  turtle.summarize(opts.args)
end, { nargs = '?' })

vim.api.nvim_create_user_command('TurtlePropose', function(opts)
  turtle.propose(opts.args)
end, { nargs = '+' })

vim.api.nvim_create_user_command('TurtleRequestExecution', function(opts)
  turtle.request_execution(opts.args)
end, { nargs = '+' })

vim.api.nvim_create_user_command('TurtleReceipts', function(opts)
  turtle.receipts(opts.args)
end, { nargs = '?' })
