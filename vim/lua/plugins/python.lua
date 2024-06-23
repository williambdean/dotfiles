return {
	{
		"jpalardy/vim-slime",
		config = function()
			vim.g.slime_target = "tmux"
			vim.g.slime_python_ipython = 1
			vim.g.slime_default_config =
				{ socket_name = "default", target_pane = "{last}", python_ipython = 0, dispatch_ipython_pause = 100 }
			vim.g.slime_bracketed_paste = 1
		end,
	},
	{ "hanschen/vim-ipython-cell" },
}
