local set = vim.opt_local

set.tabstop = 2
set.shiftwidth = 2
set.expandtab = true

local admonition = require "config.admonition"
vim.api.nvim_create_user_command(
  "Admonition",
  admonition.picker,
  { range = true }
)

local execute = require "config.execute"

local opts = {
  noremap = true,
  silent = true,
  buffer = true,
}
vim.keymap.set("n", "<leader>x", execute.copy_output_to_clipboard, opts)
