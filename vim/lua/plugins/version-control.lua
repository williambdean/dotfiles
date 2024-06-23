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
			vim.keymap.set("n", "<leader>oo", "<CMD>Octo<CR>", { silent = true })
			vim.keymap.set("i", "@", "@<C-x><C-o>", { buffer = true, silent = true })
			vim.keymap.set("i", "#", "#<C-x><C-o>", { silent = true, buffer = true })
			require("octo").setup({ enable_builtin = true })
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
	},
}
