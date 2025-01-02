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
