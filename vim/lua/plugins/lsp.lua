return {
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"ruff-lsp",
				"pyright",
				"lua-language-server",
			},
		},
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		depends = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup()

			local lspconfig = require("lspconfig")
			lspconfig.ruff_lsp.setup({})
			lspconfig.pyright.setup({})
			lspconfig.lua_ls.setup({ ft = "lua" })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

					local opts = { buffer = ev.buf }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>=", vim.lsp.buf.format, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					-- vim.keymap.set("n", "<leader>e", vim.lsp.diagnostic.show_line_diagnostics, opts)
				end,
			})
			-- Define a global variable to control formatting
			vim.g.lsp_format_enabled = true

			-- Modify the autocmd to check the global variable before formatting
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = buffer,
				callback = function()
					if vim.g.lsp_format_enabled then
						vim.lsp.buf.format({ async = false })
					end
				end,
			})

			-- Define the commands to enable and disable formatting
			vim.api.nvim_command("command! LspEnableFormat let g:lsp_format_enabled = v:true")
			vim.api.nvim_command("command! LspDisableFormat let g:lsp_format_enabled = v:false")
		end,
	},
	{
		"neovim/nvim-lspconfig",
	},
}
