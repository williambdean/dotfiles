local terminal = require "config.terminal"

local opts = {
  noremap = true,
  silent = true,
  buffer = true,
}
vim.keymap.set({ "n", "v" }, "<leader>x", function(args)
  local mode = vim.fn.mode()
  local command

  if mode == "n" then
    -- Called from normal mode
    command = terminal.get_buffer_lines()
  elseif mode == "v" then
    vim.notify "Called from visual mode"
  elseif mode == "V" then
    local lines = terminal.get_visual_lines()
    command = table.concat(lines, "\n")
  end
  terminal.open_terminal(true)
  terminal.send_command(command)
end, opts)
