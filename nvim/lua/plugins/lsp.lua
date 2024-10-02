local function get_stylua_config()
    local lspconfig = require("lspconfig")
    local util = require("lspconfig/util")

    local stylua_config_path = util.path.join(vim.fn.getcwd(), "stylua.toml")
    if util.path.exists(stylua_config_path) then
        return {
            format = {
                enable = true,
                config = stylua_config_path,
            },
        }
    end

    local config = {
        format = {
            enable = true,
            defaultConfig = {
                indentType = "Spaces",
                indentWidth = 4,
                columnWidth = 80,
                lineEndings = "Unix",
            },
        },
    }

    return config
end

return {
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                "ruff-lsp",
                "pyright",
                "lua-language-server",
                "yaml-language-server",
                "shfmt",
            },
        },
        config = function()
            require("mason").setup({
                pip = {
                    upgrade_pip = true,
                },
            })
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        depends = {
            "williamboman/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup()

            local lspconfig = require("lspconfig")
            lspconfig.ruff_lsp.setup({})
            lspconfig.pyright.setup({})
            lspconfig.harper_ls.setup({})
            lspconfig.lua_ls.setup({
                settings = {
                    globals = { "vim" },
                    Lua = get_stylua_config(),
                },
                ft = ".lua",
            })

            local group = vim.api.nvim_create_augroup("UserLspConfig", {})
            vim.api.nvim_create_autocmd("LspAttach", {
                group = group,
                callback = function(ev)
                    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                    local opts = { buffer = ev.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set("n", "<leader>=", vim.lsp.buf.format, opts)
                    vim.keymap.set(
                        "n",
                        "<leader>ca",
                        vim.lsp.buf.code_action,
                        opts
                    )
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                    -- vim.keymap.set("n", "<leader>e", vim.lsp.diagnostic.show_line_diagnostics, opts)
                end,
            })
            -- Define a global variable to control formatting
            vim.g.lsp_format_enabled = true

            vim.diagnostic.config({
                virtual_text = {
                    prefix = "●", -- Could be '●', '▎', 'x'
                    source = "if_many", -- Or "always"
                    spacing = 5,
                    severity_limit = "Warning",
                    right_align = false, -- Align to the right
                },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
            })

            -- Modify the autocmd to check the global variable before formatting
            vim.api.nvim_create_autocmd("BufWritePre", {
                -- buffer = buffer,
                group = group,
                callback = function()
                    if vim.g.lsp_format_enabled then
                        vim.lsp.buf.format({ async = false })
                    end
                end,
            })

            -- Define the commands to enable and disable formatting
            vim.api.nvim_command(
                "command! LspEnableFormat let g:lsp_format_enabled = v:true"
            )
            vim.api.nvim_command(
                "command! LspDisableFormat let g:lsp_format_enabled = v:false"
            )
            vim.api.nvim_command(
                "command! LspFormat lua vim.lsp.buf.format({ async = false })"
            )

            -- -- For shell scripts
            -- vim.api.nvim_create_autocmd("BufWritePre", {
            --     pattern = "*.sh",
            --     group = group,
            --     callback = function()
            --         vim.cmd("!shfmt -w %")
            --     end,
            -- })

            -- Add the diagnostics to the right of the screen
            -- instead of the left side which pushes it out
            vim.diagnostic.config({
                virtual_text = true,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
    },
}
