return {
    { "tpope/vim-fugitive" },
    {
        "ruifm/gitlinker.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("gitlinker").setup({})
        end,
    },
    {
        -- "pwntester/octo.nvim",
        dir = "~/GitHub/octo.nvim",
        config = function()
            require("octo").setup({
                -- default_to_projects_v2 = true,
                use_local_fs = false,
                enable_builtin = true,
                users = "mentionable",
                -- picker = "fzf-lua",
                -- picker_config = {
                --     use_emojis = true,
                -- },
            })

            -- I have my cursor over a link that looks like this
            -- https://github.com/pwntester/octo.nvim/issue/1
            -- And would like to open this file locally
            -- octo://pwntester/octo.nvim/issue/1

            local function open_github_as_octo()
                local word = vim.fn.expand("<cWORD>")
                local match_string =
                    "https://github.com/([%w-]+)/([%w-.]+)/(%w+)/(%d+)"
                local github_link = word:match(match_string)
                if not github_link then
                    vim.cmd([[normal! gf]])
                    return
                end

                local user, repo, type, id = word:match(match_string)
                local octo_link =
                    string.format("octo://%s/%s/%s/%s", user, repo, type, id)
                vim.cmd("edit " .. octo_link)
            end

            -- Map gf to the custom function
            vim.keymap.set("n", "gf", open_github_as_octo, { silent = true })

            vim.keymap.set(
                "n",
                "<leader>oo",
                "<CMD>Octo<CR>",
                { silent = true }
            )
            vim.keymap.set(
                "n",
                "<leader>ic",
                "<CMD>Octo issue create<CR>",
                { silent = true }
            )
            vim.keymap.set(
                "i",
                "@",
                "@<C-x><C-o>",
                { buffer = true, silent = true }
            )
            vim.keymap.set(
                "i",
                "#",
                "#<C-x><C-o>",
                { silent = true, buffer = true }
            )
            vim.keymap.set(
                "n",
                "<leader>op",
                "<CMD>Octo pr list<CR>",
                { silent = true }
            )
            vim.keymap.set(
                "n",
                "<leader>oi",
                "<CMD>Octo issue list<CR>",
                { silent = true }
            )
            -- Add the key mapping only for octo filetype
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "octo",
                callback = function()
                    vim.keymap.set(
                        "n",
                        "la",
                        "<CMD>Octo label add<CR>",
                        { silent = true, buffer = true }
                    )
                end,
            })
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
            -- "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
            "ibhagwan/fzf-lua",
        },
    },
}
