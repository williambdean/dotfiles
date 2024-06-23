return {
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").create_default_mappings()
			vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
		end,
	},
}
