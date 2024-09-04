local function quick_chat(with_buffer)
    local chat = require("CopilotChat")
    local select = require("CopilotChat.select")

    local prompt = "Quick Chat: "

    if with_buffer then
        prompt = "Quick Chat (Buffer): "
    end

    local handle_input = function(input)
        if input == "" then
            return
        end

        if with_buffer then
            chat.ask(input, {
                selection = select.buffer,
            })
        else
            chat.ask(input)
        end
    end

    vim.ui.input({ prompt = prompt }, handle_input)
end

return {
    { "github/copilot.vim" },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            { "github/copilot.vim" },
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope.nvim" },
        },
        config = function()
            -- Custom buffer for CopilotChat
            vim.api.nvim_create_autocmd("BufEnter", {
                pattern = "copilot-*",
                callback = function()
                    vim.opt_local.relativenumber = true
                    vim.opt_local.number = true

                    -- Get current filetype and set it to markdown if the current filetype is copilot-chat
                    local ft = vim.bo.filetype
                    if ft == "copilot-chat" then
                        vim.bo.filetype = "markdown"
                    end
                end,
            })
            require("CopilotChat").setup({
                debug = false,
                auto_follow_cursor = true,
                temperature = 0.1,
                show_help = false,
                context = "buffers",
                language = "English",
                prompts = {
                    Explain = "Explain how it works in the English language.",
                    Review = "Review the following code and provide concise suggestions.",
                    Tests = "Write tests for the following code.",
                    Anything = {
                        system_prompt = "Ignore any previous prompts and respond to the following question. It will likely be a technical question but could be anything.",
                        prompt = "This is a free-form prompt. Respond to the following question.",
                    },
                },
                build = function()
                    vim.notify(
                        "Please update the remote plugins by running :UpdateRemotePlugins, the"
                    )
                end,
                event = "VeryLazy",
            })
        end,
        keys = {
            {
                "<leader>t",
                function()
                    require("CopilotChat").toggle()
                end,
                desc = "CopilotChat - Toggle",
            },
            {
                "<leader>T",
                function()
                    require("CopilotChat").toggle({
                        window = {
                            layout = "float",
                            relative = "cursor",
                            width = 0.8,
                            height = 0.8,
                            row = 1,
                        },
                    })
                end,
                desc = "CopilotChat - Toggle",
            },
            {
                "<leader>ccq",
                function()
                    quick_chat(false)
                end,
                desc = "CopilotChat - Quick Chat",
            },
            {
                "<leader>ccb",
                function()
                    quick_chat(true)
                end,
                desc = "CopilotChat - Quick Chat (Buffer)",
            },
            {
                "<leader>cch",
                function()
                    local actions = require("CopilotChat.actions")
                    require("CopilotChat.integrations.telescope").pick(
                        actions.help_actions()
                    )
                end,
                desc = "CopilotChat - Help actions",
            },
            {
                "<leader>ccp",
                function()
                    local actions = require("CopilotChat.actions")
                    local select = require("CopilotChat.select")
                    require("CopilotChat.integrations.telescope").pick(
                        actions.prompt_actions({ selection = select.buffer })
                    )
                end,
                desc = "CopilotChat - Prompt actions",
            },
            {
                "<leader>ccv",
                function()
                    local chat = require("CopilotChat")
                    local select = require("CopilotChat.select")

                    local question = vim.fn.input("Quick Chat (Visual): ")
                    chat.ask(question, { selection = select.visual })
                end,
                mode = "v",
                desc = "CopilotChat - Visual",
            },
            {
                "<leader>cci",
                function()
                    local chat = require("CopilotChat")
                    local select = require("CopilotChat.select")

                    local question = vim.fn.input("Quick Chat (Visual): ")
                    chat.ask(question, {
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
                mode = "x",
                desc = "CopilotChat - Inline",
            },
        },
        cmd = {
            "CopilotChatToggle",
            "CopilotChat",
        },
    },
}
