local admonition = require "config.admonition"
vim.api.nvim_create_user_command(
  "Admonition",
  admonition.picker,
  { range = true }
)
