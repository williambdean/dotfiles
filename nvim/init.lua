local opt = vim.opt

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fs({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
  })
end
opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

opt.termguicolors = true

require("lazy").setup({
  spec = {
    { import = "plugins" },
    -- { 'danilamihailov/beacon.nvim' },
    {
      "ThePrimeagen/refactoring.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
      },
      lazy = true,
      config = function()
        require("refactoring").setup()

        vim.keymap.set("x", "<leader>re", ":Refactor extract ")
        vim.keymap.set("x", "<leader>rf", ":Refactor extract_to_file ")

        vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ")

        vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var")

        vim.keymap.set("n", "<leader>rI", ":Refactor inline_func")

        vim.keymap.set("n", "<leader>rb", ":Refactor extract_block")
        vim.keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file")
      end,
    },
    { "dstein64/vim-startuptime", cmd = "StartupTime" },
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {
        -- Your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
      keys = {
        {
          "<leader>?",
          function()
            require("which-key").show({ global = false })
          end,
          desc = "Buffer Local Keymaps (which-key)",
        },
      },
    },
  },
  ui = {
    backdrop = 50,
  },
})

-- Zoom in and make the "o"nly window
vim.keymap.set(
  "n",
  "<leader>O",
  ":tab split<CR>",
  { noremap = true, silent = true, desc = "Open current buffer in a new tab" }
)

-- Enable syntax highlighting
opt.syntax = "on"

-- Set spell checking
opt.spell = true
opt.spelllang = "en_us"

-- Disable error bells
opt.errorbells = false

-- Set tab settings
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- Enable smart indentation
opt.smartindent = true

-- Show line numbers
opt.number = true

-- Disable line wrapping
opt.wrap = false

-- Enable smart case sensitivity in searches
opt.smartcase = true

-- Disable swap and backup files
opt.swapfile = false
opt.backup = false

-- Configure undo
-- opt.undodir = '~/.vim/undodir'
-- opt.undofile = true

-- Enable incremental search
opt.incsearch = true

-- Set scroll offset
opt.scrolloff = 15

-- Set relative line numbers
opt.relativenumber = true
-- Highlight line numbers
-- vim.cmd("highlight LineNr guifg=#5eacd3")       -- Change the color code as per your preference
vim.cmd("highlight CursorLineNr guifg=#fabd2f") -- Change the color code as per your preference
opt.cursorline = true
-- Turn off the line across the screen
opt.cursorlineopt = "number"

-- Set encoding
opt.encoding = "utf-8"

-- Configure backspace behavior
opt.backspace:remove("indent")
opt.backspace:append({ "indent", "eol", "start" })

-- Copy and paste to system clipboard
vim.cmd("set clipboard+=unnamedplus")
-- vim.api.nvim_set_keymap("v", "<leader>y", '"*y', { noremap = true })
--

-- opt.clipboard = "unnamedplus"

-- vim.g.clipboard = {
--     name = "WslClipboard",
--     -- copy = {
--     --     ["+"] = "clip",
--     --     ["*"] = "clip",
--     -- },
--     -- paste = {
--     --     ["+"] = 'powershell.exe -c Get-Clipboard',
--     --     ["*"] = 'powershell.exe -c Get-Clipboard',
--     -- },
--     -- paste = {
--     --     ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--     --     ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--     -- },
--     cache_enabled = 0,
-- }

vim.keymap.set("v", "<leader>y", '"*y', { noremap = true })

vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
vim.api.nvim_set_hl(0, "NonText", { bg = "#000000" })

opt.signcolumn = "yes"

-- Set color column
opt.colorcolumn = "88"
vim.cmd("highlight ColorColumn ctermbg=0 guibg=grey")
vim.cmd([[
    autocmd FileType octo setlocal colorcolumn=0
]])
vim.cmd([[
    autocmd FileType copilot-chat setlocal colorcolumn=0
]])

-- Terminal mode escape key
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })

vim.g.markdown_fenced_languages =
  { "python", "bash=sh", "yaml", "json", "vim", "lua" }

-- Go up and down with center screen
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true })

-- Search is in the center of the screen
vim.keymap.set("n", "n", "nzz", { noremap = true })
vim.keymap.set("n", "N", "Nzz", { noremap = true })

vim.cmd("command! JsonPrettify %!jq .")

local group = vim.api.nvim_create_augroup("InitGroup", { clear = true })
vim.api.nvim_create_autocmd({ "TermOpen", "TextYankPost" }, {
  group = group,
  pattern = "*",
  callback = function(ev)
    if ev.event == "TermOpen" then
      vim.cmd("startinsert | set winfixheight")
    else
      vim.highlight.on_yank({ timeout = 200 })
    end
  end,
})

vim.cmd([[
    command! Note execute 'edit ' .. expand('%:p:h') .. '/note.md'
]])

-- While in Insert mode, I want to press <C-s> to run Telescope spell_suggest
vim.keymap.set(
  "i",
  "<C-s>",
  "<C-o>:Telescope spell_suggest<CR>",
  { noremap = true, silent = true }
)
-- Same but in normal mode
vim.keymap.set("n", "<C-s>", ":Telescope spell_suggest<CR>", { noremap = true })

-- Function to toggle file in a vertical split
local function toggle_file_in_vsplit(file)
  local current_win = vim.api.nvim_get_current_win()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local notes_bufnr = -1

  for _, win in ipairs(wins) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match(file .. "$") then
      notes_bufnr = bufnr
      vim.api.nvim_win_close(win, true)
      return
    end
  end

  if notes_bufnr == -1 then
    vim.cmd("rightbelow vsplit " .. file)
    vim.cmd("wincmd l") -- Move to the newly created split
  end
end

local function create_file_toggle(file)
  return function()
    toggle_file_in_vsplit(file)
  end
end

local toggles = {
  { mapping = "<leader>N", file = "note.md" },
  { mapping = "<leader>P", file = "script.py" },
}
for _, toggle in ipairs(toggles) do
  vim.keymap.set(
    "n",
    toggle.mapping,
    create_file_toggle(toggle.file),
    { noremap = true, silent = true }
  )
end

local function is_url(text)
  return text:match("^https?://") ~= nil
end

-- Function to open URL under cursor
local function open_url()
  local cursor_word = vim.fn.expand("<cfile>")
  if is_url(cursor_word) then
    vim.fn.system(string.format('wslview "%s"', cursor_word))
  end
end

-- Map gx to open URLs
vim.keymap.set("n", "gx", open_url, { noremap = true, silent = true })

vim.g.netrw_browsex_viewer = "wslview"
