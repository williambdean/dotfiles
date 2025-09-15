--- status-line.lua
--- Add octo viewer to status line
---
local M = {}

local mapping = {
  Issue = " ",
  PullRequest = " ",
  Discussion = " ",
}

local minutes = 1
local update_rate = minutes * 1000 * 60

M.structure_notification_line = function(data)
  local lines = {}
  for _, item in ipairs(data) do
    local symbol = mapping[item.type] or ""
    table.insert(lines, string.format("%s:%s", symbol, item.count))
  end

  return table.concat(lines, " ")
end

M.notification_count = ""

M.update_notification_count = function()
  local gh = require "octo.gh"

  local jq = [[
    .
    | map(.subject.type)
    | group_by(.)
    | map({type: .[0], count: length})
  ]]

  gh.api.get {
    "/notifications",
    jq = jq,
    opts = {
      cb = gh.create_callback {
        success = function(result)
          local data = vim.json.decode(result)

          M.notification_count = M.structure_notification_line(data)
        end,
      },
    },
  }
end

M.display = function()
  if vim.g.octo_viewer == nil then
    return ""
  end
  local viewer = vim.g.octo_viewer

  if M.notification_count == "" then
    M.fetch_notifications()
  end

  if M.notification_count ~= "" then
    return M.notification_count .. "  " .. viewer
  end

  return " " .. viewer
end

M.last_fetched = 0

M.fetch_notifications = function()
  local current_time = vim.uv.hrtime() / 1e6 -- Convert to milliseconds
  if current_time - M.last_fetched < update_rate then
    return
  end

  M.last_fetched = current_time

  M.update_notification_count()
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_x = { M.display },
      },
    },
  },
}
