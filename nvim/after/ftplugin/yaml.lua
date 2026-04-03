-- Taken from https://www.youtube.com/watch?v=pKCzpfqBbYs
local set = vim.opt_local

require("config.workflow").setup()

set.cursorcolumn = true
set.expandtab = true
set.shiftwidth = 2
set.softtabstop = 2
set.tabstop = 2

vim.keymap.set("n", "<C-b>", function()
  local path = vim.fn.expand "%:p"
  local filename = path:match ".*/.github/workflows/([^/]+)%.ya?ml$"

  if not filename then
    vim.notify("Not a workflow file", vim.log.levels.WARN)
    return
  end

  local utils = require "octo.utils"
  local repo = utils.get_remote_name()
  if not repo then
    vim.notify("No git remote found", vim.log.levels.ERROR)
    return
  end

  local url = string.format(
    "https://github.com/%s/actions/workflows/%s.yml",
    repo,
    filename
  )
  require("octo.navigation").open_in_browser_raw(url)
end, { buffer = true, silent = true })

vim.lsp.config.yamlls.settings = {
  yaml = {
    validate = true,
    schemas = {
      ["https://json.schemastore.org/github-workflow"] = ".github/workflows/*",
      ["https://json.schemastore.org/github-action"] = ".github/actions.{yml,yaml}",
      ["https://json.schemastore.org/conda-forge"] = "environment.{yml,yaml}",
      ["https://json.schemastore.org/pre-commit-config"] = ".pre-commit-config.{yml,yaml}",
    },
  },
}
