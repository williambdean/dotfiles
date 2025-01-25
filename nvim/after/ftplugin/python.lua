local terminal = require "config.terminal"
local python = require "config.python"

local opts = {
  noremap = true,
  silent = true,
  buffer = true,
}
vim.keymap.set("n", "<leader>x", function(args)
  local filename = vim.fn.expand "%:p"

  local command
  if python.has_ipython() then
    command = "ipython -i " .. filename
  else
    command = "python -i " .. filename
  end

  terminal.open_terminal(true)
  terminal.send_command(command)
end, opts)
