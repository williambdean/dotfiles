local set = vim.opt_local

set.tabstop = 2
set.shiftwidth = 2
set.expandtab = true

-- Map of fenced code block language to indent width
local indent_map = {
  python = 4,
  py = 4,
  lua = 2,
  rust = 4,
  rs = 4,
  bash = 2,
  sh = 2,
  terminal = 2,
  zsh = 2,
}

-- Get the language of the fenced code block at cursor, if any
local function get_code_block_lang()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")
  if not ok or not parser then
    return nil
  end

  local tree = parser:parse()[1]
  if not tree then
    return nil
  end

  local root = tree:root()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1] - 1
  local col = pos[2]

  local node = root:descendant_for_range(row, col, row, col)
  while node do
    if node:type() == "fenced_code_block" then
      for child in node:iter_children() do
        if child:type() == "info_string" then
          local text = vim.treesitter.get_node_text(child, bufnr)
          if text then
            return vim.split(text, "%s")[1]
          end
        end
      end
      return nil
    end
    node = node:parent()
  end
  return nil
end

-- Update buffer-local indent settings based on cursor position
local function update_indent()
  local lang = get_code_block_lang()
  local width = lang and indent_map[lang]
  if width then
    vim.bo.shiftwidth = width
    vim.bo.tabstop = width
    vim.bo.softtabstop = width
  else
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end
end

-- Track cursor position to detect entering/leaving code blocks
vim.api.nvim_create_autocmd("CursorMoved", {
  buffer = 0,
  callback = update_indent,
})

-- Also update on buffer re-entry
vim.api.nvim_create_autocmd("BufEnter", {
  buffer = 0,
  callback = update_indent,
})

-- Set initial indent based on starting cursor position
update_indent()

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
