local execute = require "config.execute"

local opts = {
  noremap = true,
  silent = true,
  buffer = true,
}
vim.keymap.set("n", "<leader>x", execute.copy_output_to_clipboard, opts)
