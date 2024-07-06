return {
	{ "nvim-telescope/telescope-symbols.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
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
					require("telescope.builtin").find_files()
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
					require("telescope.builtin").live_grep()
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
