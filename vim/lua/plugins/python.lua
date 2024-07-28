function python_main_block()
	-- Go to the end of the file
	vim.api.nvim_command("normal! G")
	-- Insert Python main block
	vim.api.nvim_buf_set_lines(0, -1, -1, false, {
		"",
		"",
		'if __name__ == "__main__":',
		"    # TODO: write your code here",
	})
	vim.api.nvim_command("normal! G")
end

-- Map <leader>mb to call the function
vim.api.nvim_set_keymap("n", "<leader>mb", ":lua python_main_block()<CR>", { noremap = true, silent = true })

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
