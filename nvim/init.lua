local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.termguicolors = true

require("lazy").setup({
  spec = {
    { import = "plugins" },
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
    backdrop = 80,
  },
})

-- Move around windows with vim keys
vim.api.nvim_set_keymap(
  "n",
  "<leader>h",
  ":wincmd h<CR>",
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>j",
  ":wincmd j<CR>",
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>k",
  ":wincmd k<CR>",
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>l",
  ":wincmd l<CR>",
  { noremap = true, silent = true }
)

-- Color scheme
vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])

-- Zoom in and make the "o"nly window
vim.keymap.set(
  "n",
  "<leader>O",
  ":tab split<CR>",
  { noremap = true, silent = true }
)

-- Enable syntax highlighting
vim.cmd("syntax on")

-- Set spell checking
vim.opt.spell = true
vim.opt.spelllang = "en_us"

-- Disable error bells
vim.opt.errorbells = false

-- Set tab settings
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable smart indentation
vim.opt.smartindent = true

-- Show line numbers
vim.opt.number = true

-- Disable line wrapping
vim.opt.wrap = false

-- Enable smart case sensitivity in searches
vim.opt.smartcase = true

-- Disable swap and backup files
vim.opt.swapfile = false
vim.opt.backup = false

-- Configure undo
-- vim.opt.undodir = '~/.vim/undodir'
-- vim.opt.undofile = true

-- Enable incremental search
vim.opt.incsearch = true

-- Set scroll offset
vim.opt.scrolloff = 15

-- Set relative line numbers
vim.opt.relativenumber = true
-- Highlight line numbers
-- vim.cmd("highlight LineNr guifg=#5eacd3")       -- Change the color code as per your preference
vim.cmd("highlight CursorLineNr guifg=#fabd2f") -- Change the color code as per your preference
vim.opt.cursorline = true
-- Turn off the line across the screen
vim.opt.cursorlineopt = "number"

-- Set encoding
vim.opt.encoding = "utf-8"

-- Configure backspace behavior
vim.opt.backspace:remove("indent")
vim.opt.backspace:append({ "indent", "eol", "start" })

-- Copy and paste to system clipboard
vim.cmd("set clipboard+=unnamedplus")
-- vim.api.nvim_set_keymap("v", "<leader>y", '"*y', { noremap = true })
--

-- vim.opt.clipboard = "unnamedplus"

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

vim.api.nvim_set_keymap("v", "<leader>y", '"*y', { noremap = true })

vim.cmd("highlight Normal guibg=#00000070 ctermbg=NONE")
vim.cmd("highlight NonText guibg=#00000070 ctermbg=NONE")

-- Set color column
vim.opt.colorcolumn = "88"
vim.cmd("highlight ColorColumn ctermbg=0 guibg=grey")
vim.cmd([[
    autocmd FileType octo setlocal colorcolumn=0
]])
vim.cmd([[
    autocmd FileType copilot-chat setlocal colorcolumn=0
]])

-- Terminal mode escape key
vim.api.nvim_set_keymap(
  "t",
  "<Esc>",
  "<C-\\><C-n>",
  { noremap = true, silent = true }
)

vim.g.markdown_fenced_languages =
  { "python", "bash=sh", "yaml", "json", "vim", "lua" }

-- Go up and down with center screen
vim.api.nvim_set_keymap("n", "<C-d>", "<C-d>zz", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-u>", "<C-u>zz", { noremap = true })

-- Search is in the center of the screen
vim.api.nvim_set_keymap("n", "n", "nzz", { noremap = true })
vim.api.nvim_set_keymap("n", "N", "Nzz", { noremap = true })

vim.cmd("command! JsonPrettify %!jq .")

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  command = "startinsert | set winfixheight",
})
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

vim.cmd([[
    command! Note execute 'edit ' .. expand('%:p:h') .. '/note.md'
]])

-- While in Insert mode, I want to press <C-s> to run Telescope spell_suggest
vim.api.nvim_set_keymap(
  "i",
  "<C-s>",
  "<C-o>:Telescope spell_suggest<CR>",
  { noremap = true, silent = true }
)
-- Same but in normal mode
vim.api.nvim_set_keymap(
  "n",
  "<C-s>",
  ":Telescope spell_suggest<CR>",
  { noremap = true }
)

-- Function to toggle notes.md in a vertical split
local function toggle_file_in_vsplit(file)
  local current_win = vim.api.nvim_get_current_win()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local notes_bufnr = -1

  if #wins == 1 then
    print("This is the only buffer open.")
    return
  end

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

local function toggle_notes_in_vsplit()
  toggle_file_in_vsplit("notes.md")
end

local function toggle_python_script_in_vsplit()
  toggle_file_in_vsplit("script.py")
end

vim.keymap.set(
  "n",
  "<leader>N",
  toggle_notes_in_vsplit,
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<leader>P",
  toggle_python_script_in_vsplit,
  { noremap = true, silent = true }
)
