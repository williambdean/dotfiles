local set = vim.opt_local

set.expandtab = true
set.shiftwidth = 2
set.softtabstop = 2
set.tabstop = 2

local opts = {
  noremap = true,
  silent = true,
  buffer = true,
}
vim.keymap.set("n", "<leader>x", ":luafile %<CR>", opts)
