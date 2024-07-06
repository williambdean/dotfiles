return {
	-- {
	-- 	"ggandor/leap.nvim",
	-- 	config = function()
	-- 		require("leap").create_default_mappings()
	-- 		vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
	-- 	end,
	-- },
	{
		"smoka7/hop.nvim",
		version = "*",
		opts = {
			keys = "etovxqpdygfblzhckisuran",
		},
		config = function()
			require("hop").setup({
				multi_windows = true,
			})
			vim.api.nvim_set_keymap(
				"n",
				"s",
				"<cmd>lua require'hop'.hint_char1()<cr>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"f",
				"<cmd>lua require'hop'.hint_char1({ current_line_only = true })<cr>",
				{ noremap = true, silent = true }
			)
		end,
	},
	-- {-- place this in one of your configuration file(s)
	--   "folke/flash.nvim",
	--   event = "VeryLazy",
	--   ---@type Flash.Config
	--   opts = {},
	--   -- stylua: ignore
	--   keys = {
	--     { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
	--     { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
	--     { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
	--     { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
	--     { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
	--   },
	-- }
}
