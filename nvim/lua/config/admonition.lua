---Picker to create admonitions in markdown files based on selected block of text
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local themes = require "telescope.themes"

local M = {}

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

local kinds = {
  "NOTE",
  "TIP",
  "IMPORTANT",
  "WARNING",
  "CAUTION",
}

local function to_title_case(str)
  return str:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
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

local create_callback = function(start, stop, lines)
  return function(kind)
    local admonition = create_admonition(kind, lines)
    vim.api.nvim_buf_set_lines(0, start, stop, false, admonition)
  end
end

local admonition_picker = function(opts)
  local cb = opts.cb

  pickers
    .new(opts, {
      finder = finders.new_table {
        results = kinds,
        entry_maker = function(entry)
          return {
            value = entry,
            display = to_title_case(entry),
            ordinal = entry,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection == nil then
            return
          end
          local kind = selection.value

          cb(kind)
        end)
        return true
      end,
    })
    :find()
end

M.picker = function(opts)
  local start = opts.line1 - 1
  local stop = opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, start, stop, false)
  local opts = vim.deepcopy(dropdown_opts)
  opts.cb = create_callback(start, stop, lines)
  admonition_picker(opts)
end

return M
