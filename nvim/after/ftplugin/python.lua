local terminal = require "config.terminal"
local python = require "config.python"

local is_test_file = function(filename)
  return filename:match "test_.*%.py"
end

local opts = {
  noremap = true,
  silent = true,
  buffer = true,
}
vim.keymap.set("n", "<leader>x", function(args)
  local filename = vim.fn.expand "%:p"

  if is_test_file(filename) then
    local tests = terminal.get_test_under_cursor()
    terminal.run_test({
      args = "--pdb -vvv",
    }, tests)
    return
  end

  local command
  if python.has_uv() then
    command = "uv run python -i " .. filename
  elseif python.has_ipython() then
    command = "ipython -i " .. filename
  else
    command = "python3 -i " .. filename
  end

  terminal.open_terminal(true)
  terminal.send_command(command)
end, opts)
