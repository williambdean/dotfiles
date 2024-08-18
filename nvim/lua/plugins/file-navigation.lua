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

return {
    { "nanotee/zoxide.vim" },
    {
        "stevearc/oil.nvim",
        config = function()
            vim.keymap.set(
                "n",
                "-",
                "<CMD>Oil<CR>",
                { desc = "Open parent directory" }
            )

            require("oil").setup({
                view_options = {
                    show_hidden = true,
                },
            })
        end,
    },
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            local harpoon = require("harpoon")

            vim.keymap.set("n", "<leader>a", function()
                harpoon:list():add()
            end)
            vim.keymap.set("n", "<C-e>", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end)

            vim.keymap.set("n", "<C-h>", function()
                harpoon:list():select(1)
            end)
            vim.keymap.set("n", "<C-t>", function()
                harpoon:list():select(2)
            end)
            vim.keymap.set("n", "<C-w>", function()
                harpoon:list():select(3)
            end)
            vim.keymap.set("n", "<C-s>", function()
                harpoon:list():select(4)
            end)

            vim.keymap.set("n", "<C-n>", function()
                harpoon:list():next()
            end)
            vim.keymap.set("n", "<C-p>", function()
                harpoon:list():prev()
            end)

            harpoon:setup({})
        end,
    },
}
