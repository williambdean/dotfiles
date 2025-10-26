local set = vim.opt_local

set.expandtab = true
set.shiftwidth = 2
set.softtabstop = 2
set.tabstop = 2

vim.keymap.set(
  "n",
  "<leader>x",
  "<CMD>Query<CR>",
  { noremap = true, silent = true, buffer = true }
)
