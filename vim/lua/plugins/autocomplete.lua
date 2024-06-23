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
						selection = select.buffer,
					})
				else
					ask(input)
				end
			end
			vim.keymap.set("n", "<leader>ccq", function()
				quick_chat(false)
			end, { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>ccb", function()
				quick_chat(true)
				vim.notify("Chatting with a buffer.")
			end, { noremap = true, silent = true })

			vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
				chat.ask(args.args, { selection = select.visual })
			end, { nargs = "*", range = true })
			vim.keymap.set("x", "<leader>ccv", ":CopilotChatVisual<CR>", { noremap = true, silent = true })

			vim.api.nvim_create_user_command("CopilotChatInline", function(args)
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
			end, { nargs = "*", range = true })
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
				function()
					require("CopilotChat").toggle()
				end,
				desc = "CopilotChat - Toggle",
			},
			{
				"<leader>cch",
				function()
					local actions = require("CopilotChat.actions")
					require("CopilotChat.integrations.telescope").pick(actions.help_actions())
				end,
				desc = "CopilotChat - Help actions",
			},
			{
				"<leader>ccp",
				function()
					local actions = require("CopilotChat.actions")
					require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
				end,
				desc = "CopilotChat - Prompt actions",
			},
		},
	},
}
