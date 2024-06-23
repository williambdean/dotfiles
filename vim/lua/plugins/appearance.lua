return {
	{
		"NvChad/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	},
	{ "ellisonleao/gruvbox.nvim", priority = 1000 },
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "gruvbox",
					section_separators = { "", "" },
					component_separators = { "", "" },
				},
				sections = {
					lualine_c = { { "filename", path = 1 } },
					lualine_y = {
						{ require("recorder").displaySlots },
					},
					lualine_z = {
						{ require("recorder").recordingStatus },
					},
				},
			})
		end,
	},
}
