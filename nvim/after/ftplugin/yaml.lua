-- Taken from https://www.youtube.com/watch?v=pKCzpfqBbYs
local set = vim.opt_local

set.cursorcolumn = true
set.expandtab = true
set.shiftwidth = 2
set.softtabstop = 2
set.tabstop = 2

require("lspconfig").yamlls.setup {
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
}
