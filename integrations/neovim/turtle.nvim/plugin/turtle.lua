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
