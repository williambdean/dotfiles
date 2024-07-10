local find_site_packages = function()
	local site_packages = vim.trim(vim.fn.system("python -c 'import site; print(site.getsitepackages()[0])'"))

	return site_packages
end

return {
	{ "nvim-telescope/telescope-symbols.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
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
