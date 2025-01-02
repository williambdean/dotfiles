-- Additional commands for interacting with GitHub issues
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local themes = require "telescope.themes"

local octo_commands = require "octo.commands"
local octo_utils = require "octo.utils"

local M = {}

local options = {
  { stateReason = "COMPLETED", display = "Completed" },
  { stateReason = "NOT_PLANNED", display = "Not Planned" },
  { stateReason = "DUPLICATE", display = "Duplicate" },
}

-- Taken from octo.nvim/pickers/telescope/provider.lua
local dropdown_opts = themes.get_dropdown {
  layout_config = {
    width = 0.4,
    height = 15,
  },
  prompt_title = false,
  results_title = false,
  previewer = false,
}

function M.close_issue()
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer = _G.octo_buffers[bufnr]
  if not buffer then
    octo_utils.notify "Not in an Octo buffer"
    return
  end

  if not buffer:isIssue() then
    octo_utils.notify "Not an issue buffer"
    return
  end

  local opts = vim.deepcopy(dropdown_opts)
  pickers
    .new(opts, {
      prompt_title = "Close Issue",
      finder = finders.new_table {
        results = options,
        entry_maker = function(entry)
          return {
            value = entry.stateReason,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection == nil then
            return
          end

          octo_commands.change_state(selection.value)
        end)
        return true
      end,
    })
    :find()
end

return M
