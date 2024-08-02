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
        "pwntester/octo.nvim",
        config = function()
            require("octo").setup({
                enable_builtin = true,
            })

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
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
        },
    },
}
