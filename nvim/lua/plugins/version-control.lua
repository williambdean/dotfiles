local vim = vim
local _, Job = pcall(require, "plenary.job")

-- @param title string
-- @param body string
local function create_issue(title, body)
    if not Job then
        return
    end

    body = body or ""

    Job:new({
        enable_recording = true,
        command = "gh",
        args = { "issue", "create", "--title", title, "--body", body },
        on_exit = vim.schedule_wrap(function()
            print("Created issue: " .. title)
        end),
    }):start()
end

local function get_visual_lines()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- Extract the lines between these positions
    return vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
end

local function create_issues()
    local lines = get_visual_lines()
    for _, line in ipairs(lines) do
        -- I want to seperate the line into title and body where the separation is the ":" character. If there is
        -- no ":" character, then the whole line is the title
        -- Example: "Title: Body" -> title = "Title", body = "Body"
        -- Example: "Title" -> title = "Title", body = ""
        -- Example: "Title: Body: More body" -> title = "Title", body = "Body: More body"
        -- Example: "Title: Body: More body: Even more body" -> title = "Title", body = "Body: More body: Even more body"
        local title, body = line:match("^(.-):%s*(.*)$")
        if not title then
            title = line
            body = ""
        end
        create_issue(title, body)
    end
end

-- Add mapping to create issues when in visual selection
vim.keymap.set("v", "<leader>ic", create_issues, { silent = true })

local function open_github_as_octo_buffer()
    local word = vim.fn.expand("<cWORD>")
    local match_string = "https://github.com/([%w-]+)/([%w-.]+)/(%w+)/(%d+)"
    local github_link = word:match(match_string)
    if not github_link then
        vim.cmd([[normal! gf]])
        return
    end

    local user, repo, type, id = word:match(match_string)
    local octo_link = string.format("octo://%s/%s/%s/%s", user, repo, type, id)
    vim.cmd("edit " .. octo_link)
end

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

            -- Map gf to the custom function
            vim.keymap.set(
                "n",
                "gf",
                open_github_as_octo_buffer,
                { silent = true }
            )

            -- Use telescope to find a commit hash and add it where the cursor is
            vim.keymap.set("n", "<leader>ch", function()
                require("telescope.builtin").git_commits({
                    attach_mappings = function(_, map)
                        map("i", "<CR>", function(bufnr)
                            local value =
                                require("telescope.actions.state").get_selected_entry(
                                    bufnr
                                )
                            require("telescope.actions").close(bufnr)

                            local hash = value.value
                            vim.fn.setreg('"', hash)
                        end)
                        return true
                    end,
                })
            end, { silent = true })

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
