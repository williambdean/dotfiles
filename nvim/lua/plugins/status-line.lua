--- status-line.lua
--- Add octo viewer to status line

local display_viewer = function()
  if vim.g.octo_viewer == nil then
    return ""
  end
  local viewer = vim.g.octo_viewer

  return " " .. viewer
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_x = { display_viewer },
      },
    },
  },
}
