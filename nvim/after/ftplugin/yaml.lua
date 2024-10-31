-- Taken from https://www.youtube.com/watch?v=pKCzpfqBbYs
vim.opt_local.cursorcolumn = true
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true

require("lspconfig").yamlls.setup({
  settings = {
    yaml = {
      validate = true,
      schemas = {
        ["https://json.schemastore.org/github-workflow"] = ".github/workflows/*",
        ["https://json.schemastore.org/github-action"] = ".github/actions.{yml,yaml}",
        ["https://json.schemastore.org/conda-forge"] = "environment.{yml,yaml}",
        ["https://json.schemastore.org/pre-commit-config"] = ".pre-commit-config.{yml,yaml}",
      },
    },
  },
})
