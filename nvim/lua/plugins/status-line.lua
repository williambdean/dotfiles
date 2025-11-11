--- status-line.lua
--- Add octo viewer to status line
---
local M = {}

---@alias Type "Commit" | "Issue" | "PullRequest" | "Discussion"

---@class NotificationCount
---@field type Type
---@field count number

---@type table<Type, string>
local mapping = {
  Commit = " ",
  Issue = " ",
  PullRequest = " ",
  Discussion = " ",
  Release = " ",
}

local minutes = 1
local update_rate = minutes * 1000 * 60

---@param data NotificationCount[]
---@return string
M.structure_notification_line = function(data)
  local lines = {}
  for _, item in ipairs(data) do
    local symbol = mapping[item.type] or ""
    table.insert(lines, string.format("%s:%s", symbol, item.count))
  end

  return table.concat(lines, " ")
end

---@class Status
---@field last_fetched number
---@field total_notifications? integer
---@field display string

---@type Status
M.status = { last_fetched = 0, total_notifications = nil, display = "" }

---@return nil
function M.update_notification_count()
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
          ---@type NotificationCount[]
          local data = vim.json.decode(result)

          M.status.display = M.structure_notification_line(data)
          if
            M.status.total_notifications ~= nil
            and M.status.total_notifications ~= #data
          then
            vim.notify(
              "There are new GitHub notifications!",
              vim.log.levels.INFO,
              {
                title = "Octo",
              }
            )
          end
          M.status.total_notifications = #data
        end,
      },
    },
  }
end

M.fetch_notifications = function()
  local current_time = vim.uv.hrtime() / 1e6 -- Convert to milliseconds
  if current_time - M.status.last_fetched < update_rate then
    return
  end

  M.status.last_fetched = current_time

  M.update_notification_count()
end

M.display = function()
  if vim.g.octo_viewer == nil then
    return ""
  end
  local viewer = vim.g.octo_viewer

  if M.status.display == "" then
    M.fetch_notifications()
  end

  if M.status.display ~= "" then
    return M.status.display .. "  " .. viewer
  end

  return " " .. viewer
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
