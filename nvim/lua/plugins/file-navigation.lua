local is_git_repo = function()
    local git_dir = vim.fn.system("git rev-parse --is-inside-work-tree")
    return vim.v.shell_error == 0
end

local find_site_packages = function()
    return vim.trim(
        vim.fn.system(
            "python -c 'import site; print(site.getsitepackages()[0])'"
        )
    )
end

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
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
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

            vim.keymap.set("n", "<leader>1", function()
                harpoon:list():select(1)
            end)
            vim.keymap.set("n", "<leader>2", function()
                harpoon:list():select(2)
            end)
            vim.keymap.set("n", "<leader>3", function()
                harpoon:list():select(3)
            end)
            vim.keymap.set("n", "<leader>4", function()
                harpoon:list():select(4)
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
    { "nvim-telescope/telescope-symbols.nvim" },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        keys = {
            {
                "<leader>pf",
                function()
                    require("telescope.builtin").find_files({
                        cwd = find_site_packages(),
                        glob_pattern = "*.py",
                    })
                end,
            },
            {
                "<leader>pg",
                function()
                    require("telescope.builtin").live_grep({
                        cwd = find_site_packages(),
                        glob_pattern = "*.py",
                    })
                end,
            },
            {
                "<leader>fc",
                function()
                    require("telescope.builtin").resume()
                end,
            },
            {
                "<leader>fp",
                function()
                    require("telescope.builtin").oldfiles({ only_cwd = true })
                end,
            },
            {
                "<leader>ff",
                function()
                    local cwd
                    if vim.bo.filetype == "oil" then
                        cwd = require("oil").get_current_dir()
                    else
                        cwd = vim.fn.expand("%:p:h")
                    end

                    -- params = {
                    --     cwd = cwd,
                    --     search_dirs = { cwd },
                    -- }
                    params = {}

                    -- TODO: Bug where in a git repo but in a non-git directory

                    local search
                    if is_git_repo() then
                        search = require("telescope.builtin").git_files
                        -- params.use_git_root = false
                    else
                        search = require("telescope.builtin").find_files
                    end

                    search(params)
                end,
            },
            {
                "<leader>fd",
                function()
                    require("telescope.builtin").find_files({ hidden = true })
                end,
            },
            {
                "<leader>fg",
                function()
                    cwd = require("oil").get_current_dir()
                    -- params = {
                    --     cwd = cwd,
                    --     search_dirs = { cwd },
                    -- }
                    params = {}
                    require("telescope.builtin").live_grep(params)
                end,
            },
            {
                "<leader>fb",
                function()
                    require("telescope.builtin").buffers()
                end,
            },
            {
                "<leader>fh",
                function()
                    require("telescope.builtin").help_tags()
                end,
            },
        },
    },
}
