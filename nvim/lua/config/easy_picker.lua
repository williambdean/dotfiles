--- Picker where table of items is passed
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}

---@alias PickerOpts
---@field selected_callback function
---@field multi_selected_callback function
---@field close_picker boolean
---@field prompt_title string
---@field create_value function|nil

local notify = function(selected)
  vim.notify("Selected: " .. vim.inspect(selected))
end

local identity = function(x)
  return x
end

---Create a picker
---@param items table
---@param opts PickerOpts
M.new = function(items, opts)
  opts = opts or {}

  opts.create_value = opts.create_value or identity
  opts.close_picker = opts.close_picker or true
  opts.prompt_title = opts.prompt_title or "Select an item"

  opts.selected_callback = opts.selected_callback or notify
  opts.multi_selected_callback = opts.multi_selected_callback
    or function(selected)
      for _, selection in ipairs(selected) do
        opts.selected_callback(selection)
      end
    end

  pickers
    .new({
      prompt_title = opts.prompt_title,
      finder = finders.new_table {
        results = items,
        entry_maker = function(entry)
          local value = opts.create_value(entry)
          return {
            value = value,
            display = value,
            ordinal = value,
            obj = entry,
            syntax = "python",
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local selections = picker:get_multi_selection()

          if opts.close_picker then
            actions.close(prompt_bufnr)
          end

          if #selections == 0 then
            opts.selected_callback(selection)
            return
          end

          if opts.multi_selected_callback then
            opts.multi_selected_callback(selections)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
