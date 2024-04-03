local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    -- latest stable release lazypath
    "--branch=stable", 
    })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lazy").setup({
    -- {
    --   "christoomey/vim-tmux-navigator",
    --   cmd = {
    --     "TmuxNavigateLeft",
    --     "TmuxNavigateDown",
    --     "TmuxNavigateUp",
    --     "TmuxNavigateRight",
    --     "TmuxNavigatePrevious",
    --   },
    --   keys = {
    --     { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    --     { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    --     { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    --     { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    --     { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    --   },
    -- },
    { "tpope/vim-commentary" }, 
    { "tpope/vim-fugitive" },
    -- Python development
    { "davidhalter/jedi-vim" },
    { "jpalardy/vim-slime" }, 
    { "hanschen/vim-ipython-cell" },
    -- Colors
    { "ellisonleao/gruvbox.nvim", priority = 1000 },
    { "nvim-treesitter/nvim-treesitter" },
    { "folke/noice.nvim", dependencies = { "folke/nvim-notify" }}, 
	{ "github/copilot.vim" }, 
	{ 
		"nvim-tree/nvim-tree.lua", 
		version = "*", 
		lazy = false, 
		dependencies = { "nvim-tree/nvim-web-devicons" }, 
		config = function()
			require("nvim-tree").setup({})
		end, 
	},
	{ "CopilotC-Nvim/CopilotChat.nvim", 
		branch = "canary", 
		dependencies = { 
			{ "github/copilot.vim" }, 
			{ "nvim-lua/plenary.nvim" },
		},
        config = function()
            require("CopilotChat").setup({
                debug = false, 
                show_help = "yes", 
                language = "English", 
                prompts = {
                    Explain = "Explain how it works in the English language.",
                    Review = "Review the following code and provide concise suggestions.",
                },
                build = function()
                    vim.notify("Please update the remote plugins by running :UpdateRemotePlugins, the")
                end,
                event = "VeryLazy", 
            })
        end,
	},
	{ "nvim-telescope/telescope.nvim", dependencies = { 'nvim-lua/plenary.nvim' } },
	{ "dense-analysis/ale" },
	{ 
        "folke/noice.nvim", 
        event = "VeryLazy", 
        dependencies = {
            "MunifTanjim/nui.nvim",
            "folke/nvim-notify",
        },
        config = function() 
		require("noice").setup({
			lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true, 
                    ["vim.lsp.util.stylize_markdown"] = true, 
                    ["cmp.entry.get_documentation"] = true, 
                },
            }, 
			presets = {
				bottom_search = true, 
				command_palette = true, 
				long_message_to_split = true, 
				inc_rename = false, 
				lsp_doc_border = false, 
			}, 
		})
        end,
    }, 
    { "stevearc/oil.nvim" },
    { 
        "ThePrimeagen/harpoon", 
        branch = "harpoon2", 
        dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    },
})

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Move around windows with vim keys 
vim.api.nvim_set_keymap("n", "<leader>h", ":wincmd h<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>j", ":wincmd j<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>k", ":wincmd k<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>l", ":wincmd l<CR>", { noremap = true, silent = true })

-- harpoon setup
local harpoon = require("harpoon")
harpoon:setup({})

-- Using telescope to toggle harpoon
-- local conf = require("telescope.config").values
-- local function toggle_telescope(harpoon_files)
--     local file_paths = {}
--     for _, item in ipairs(harpoon_files.items) do
--         table.insert(file_paths, item.value)
--     end

--     require("telescope.pickers").new({}, {
--         prompt_title = "Harpoon", 
--         finder = require("telescope.finders").new_table({
--             results = file_paths, 
--         }), 
--         previewer = conf.file_previewer({}), 
--         sorter = conf.generic_sorter({}),
--     }):find()
-- end
-- vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end)

vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)

vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)

-- Using the vimtree plugin
vim.api.nvim_set_keymap("n", "<leader>t", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

-- CopilotChatToggle
vim.api.nvim_set_keymap("n", "<leader>cc", ":CopilotChatToggle<CR>", { noremap = true, silent = true })

-- Colorscheme
vim.o.background = "dark" -- or "light" for light mode
vim.cmd([[colorscheme gruvbox]])

-- Python and Slime
vim.g.slime_target = "tmux"
vim.g.slime_python_ipython = 1
vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}", python_ipython = 0, dispatch_ipython_pause = 100 }
vim.g.slime_bracketed_paste = 1

-- Enable syntax highlighting
-- vim.cmd('syntax on')

-- Set spell checking
vim.opt.spell = true

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

-- Set encoding
vim.opt.encoding = 'utf-8'

-- Configure backspace behavior
vim.opt.backspace:remove('indent')
vim.opt.backspace:append({'indent', 'eol', 'start'})

-- Set color column
-- vim.opt.colorcolumn = '88'
-- vim.cmd('highlight ColorColumn ctermbg=0 guibg=grey')
