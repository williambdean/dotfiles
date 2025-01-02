--- status-line.lua
--- Add octo viewer to status line
local viewer
local called = false

local get_current_viewer = function()
  local gh = require "octo.gh"
  local query = [[
  query {
    viewer {
      login
    }
  }
  ]]
  return gh.graphql {
    query = query,
    jq = ".data.viewer.login",
    opts = {
      cb = function(data)
        viewer = data
      end,
    },
  }
end

local display_viewer = function()
  if viewer == nil and not called then
    called = true
    vim.notify "Making GitHub API call"
    get_current_viewer()
  end

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
