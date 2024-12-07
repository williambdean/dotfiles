local kinds = {
  "NOTE",
  "TIP",
  "IMPORTANT",
  "WARNING",
  "CAUTION",
}

local function is_kind(kind)
  for _, k in ipairs(kinds) do
    if k == kind then
      return true
    end
  end
  return false
end

local function create_admonition(kind, lines)
  local admonition = {
    "> [!" .. kind .. "]",
    ">",
  }
  for _, line in ipairs(lines) do
    table.insert(admonition, "> " .. line)
  end
  return admonition
end

local name = "Admonition"
vim.api.nvim_create_user_command(name, function(opts)
  local kind = vim.trim(opts.args):gsub('"', "")
  if not is_kind(kind) then
    vim.notify("Invalid kind. Must be one of: " .. table.concat(kinds, ", "))
    return
  end

  local start = opts.line1 - 1
  local stop = opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, start, stop, false)

  if #lines == 0 then
    vim.notify("No lines selected")
    return
  end

  local admonition = create_admonition(kind, lines)
  vim.api.nvim_buf_set_lines(0, start, stop, false, admonition)
end, { range = true })

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      file_types = { "markdown", "octo" },
    },
  },
}
