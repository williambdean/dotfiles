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

vim.opt.termguicolors = true

require("lazy").setup({
    {
        "chrisgrieser/nvim-recorder",
        -- dependencies = "rcarriga/nvim-notify",
        opts = {},
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "gruvbox",
                    section_separators = { "", "" },
                    component_separators = { "", "" },
                },
                sections = {
                    lualine_c = { { "filename", path = 1 } },
                    lualine_y = {
                        { require("recorder").displaySlots },
                    },
                    lualine_z = {
                        { require("recorder").recordingStatus },
                    },
                },
            })
        end,
    },
    { "nanotee/zoxide.vim" },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && npm install",
        config = function() 
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" }, 
    },
    -- {
    --   "christoomey/vim-tmux-navigator",
    --   cmd = {
    --     "TmuxNavigateLeft",
    --     "TmuxNavigateDown",
    --     "TmuxNavigateUp",
    --     "TmuxNavigateRight",
    --     "TmuxNavigatePrevious",
    --   },
    --   These override with some of the harpoon commands
    --   keys = {
    --     { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    --     { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    --     { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    --     { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    --     { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    --   },
    -- },
    -- { "tpope/vim-commentary" }, 
    { "tpope/vim-fugitive" },
    {
        "ggandor/leap.nvim",
        config = function()
            require('leap').create_default_mappings()
            vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
        end,
    },
    -- Python development
    -- { "davidhalter/jedi-vim" },
    { 
        "jpalardy/vim-slime", 
        config = function() 
            vim.g.slime_target = "tmux"
            vim.g.slime_python_ipython = 1
            vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}", python_ipython = 0, dispatch_ipython_pause = 100 }
            vim.g.slime_bracketed_paste = 1
        end,
    }, 
    { "hanschen/vim-ipython-cell" },
    { 
        "williamboman/mason.nvim", 
        opts = {
            ensure_installed = {
                "pyright",
            },
        },
        config = function() 
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function() 
            require("mason").setup()
            require("mason-lspconfig").setup()

            -- require("lspconfig").pyright.setup({})

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}), 
                callback = function(ev)
                    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                    local opts = { buffer = ev.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                end, 
            })

        end,
    },
    {
        "neovim/nvim-lspconfig",
    }, 
    -- Colors
    { "ellisonleao/gruvbox.nvim", priority = 1000 },
    { "nvim-treesitter/nvim-treesitter" },
    { 
        "rcarriga/nvim-notify",
        config = function() 
            vim.api.nvim_set_keymap("n", "<leader>nd", ":lua require('notify').dismiss()<CR>", { noremap = true, silent = true })

            require("notify").setup({
                background_colour = "Normal",
                fps = 30,
                icons = {
                    DEBUG = "",
                    ERROR = "",
                    INFO = "",
                    TRACE = "✎",
                    WARN = ""
                },
                level = 2,
                minimum_width = 50,
                maximum_width = 300,
                render = "compact",
                stages = "fade_in_slide_out",
                timeout = 5000,
                top_down = true
            })
        end,
    },
    { "folke/noice.nvim", dependencies = { "rcarriga/nvim-notify" }},
    -- Autocomplete
    { "github/copilot.vim" }, 
    { 
        "nvim-tree/nvim-tree.lua", 
        version = "*", 
        lazy = false, 
        dependencies = { "nvim-tree/nvim-web-devicons" }, 
        config = function()
            -- Disable netrw
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            -- Using the vimtree plugin
            vim.api.nvim_set_keymap("n", "<leader>t", ":NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })

            require("nvim-tree").setup({
                view = {
                    width = 35, 
                    side = "left", 
                },
            })
        end, 
    },
    { 
        "CopilotC-Nvim/CopilotChat.nvim", 
        branch = "canary", 
        dependencies = { 
            { "github/copilot.vim" }, 
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope.nvim" },
        },
        config = function()
            local chat = require("CopilotChat")
            local select = require("CopilotChat.select")

            local function quick_chat(with_buffer) 
                prompt = "Quick Chat: "
                if with_buffer then
                    prompt = "Quick Chat (Buffer): "
                end
                local input = vim.fn.input(prompt)
                if input == "" then
                    return
                end

                ask = chat.ask
                if with_buffer then
                    ask(input, {
                        selection = select.buffer
                    })
                else
                    ask(input)
                end
            end
            vim.keymap.set("n", "<leader>ccq", function() quick_chat(false) end, { noremap = true, silent = true })
            vim.keymap.set("n", "<leader>ccb", 
                function() 
                    quick_chat(true) 
                    vim.notify("Chatting with a buffer.")
                end, { noremap = true, silent = true })

            vim.api.nvim_create_user_command(
            "CopilotChatVisual", 
            function(args)
                chat.ask(args.args, { selection = select.visual })
            end, 
            { nargs = "*", range = true }
            )
            vim.keymap.set("x", "<leader>ccv", ":CopilotChatVisual<CR>", { noremap = true, silent = true })

            vim.api.nvim_create_user_command(
            "CopilotChatInline", 
            function(args)
                chat.ask(args.args, { 
                    selection = select.visual,
                    window = {
                        layout = "float", 
                        relative = "cursor", 
                        width = 1, 
                        height = 0.4, 
                        row = 1, 
                    },
                })
            end, 
            { nargs = "*", range = true }
            )
            vim.keymap.set("x", "<leader>cci", ":CopilotChatInline<CR>", { noremap = true, silent = true })

            chat.setup({
                debug = false, 
                show_help = "yes", 
                context = "buffers",
                language = "English", 
                prompts = {
                    Explain = "Explain how it works in the English language.",
                    Review = "Review the following code and provide concise suggestions.",
                    Tests = "Write tests for the following code.",
                },
                build = function()
                    vim.notify("Please update the remote plugins by running :UpdateRemotePlugins, the")
                end,
                event = "VeryLazy", 
            })
        end,
        keys = {
            {
                "<leader>cct",
                function ()
                    require("CopilotChat").toggle()
                end,
                desc = "CopilotChat - Toggle",
            },
            { 
                "<leader>cch", 
                function ()
                    local actions = require("CopilotChat.actions")
                    require("CopilotChat.integrations.telescope").pick(
                    actions.help_actions()
                    )
                end,
                desc = "CopilotChat - Help actions",
            },
            {
                "<leader>ccp",
                function ()
                    local actions = require("CopilotChat.actions")
                    require("CopilotChat.integrations.telescope").pick(
                    actions.prompt_actions()
                    )
                end,
                desc = "CopilotChat - Prompt actions",
            },
        },
    },
    { 
        "nvim-telescope/telescope.nvim", 
        dependencies = { 'nvim-lua/plenary.nvim' }, 
        keys = {
            { "<leader>ff", function() require('telescope.builtin').find_files() end, },
            { "<leader>fg", function() require('telescope.builtin').live_grep() end, },
            { "<leader>fb", function() require('telescope.builtin').buffers() end, },
            { "<leader>fh", function() require('telescope.builtin').help_tags() end, },
        },
    },
    { "dense-analysis/ale" },
    { 
        "folke/noice.nvim", 
        event = "VeryLazy", 
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
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
    { 
        "stevearc/oil.nvim",
        config = function()
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

            require("oil").setup({})
        end,
    },
    { 
        "ThePrimeagen/harpoon", 
        branch = "harpoon2", 
        dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
        config = function()
            local harpoon = require("harpoon")

            vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
            vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

            vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
            vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end)
            vim.keymap.set("n", "<C-w>", function() harpoon:list():select(3) end)
            vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)

            vim.keymap.set("n", "<C-n>", function() harpoon:list():next() end)
            vim.keymap.set("n", "<C-p>", function() harpoon:list():prev() end)

            harpoon:setup({})
        end,
    },
})

-- Move around windows with vim keys 
vim.api.nvim_set_keymap("n", "<leader>h", ":wincmd h<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>j", ":wincmd j<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>k", ":wincmd k<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>l", ":wincmd l<CR>", { noremap = true, silent = true })


-- Colorscheme
vim.o.background = "dark" -- or "light" for light mode
vim.cmd([[colorscheme gruvbox]])


-- Zoom in and make the "o"nly window
vim.keymap.set("n", "<leader>o", ":tab split<CR>", { noremap = true, silent = true })

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

-- Copy and paste to system clipboard
vim.api.nvim_set_keymap('v', '<leader>y', '"*y', { noremap = true })
vim.opt.clipboard = 'unnamedplus'

-- Set color column
-- vim.opt.colorcolumn = '88'
-- vim.cmd('highlight ColorColumn ctermbg=0 guibg=grey')
--

-- Terminal mode escape key
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })

vim.g.markdown_fenced_languages = { "python", "bash=sh", "yaml", "json", "vim", "lua" }

 
