--- Link a Issue, PR, or Discussion in a buffer
--- WIP until octo.nvim has better callback support

local gh = require "octo.gh"
local gh_picker = require "octo.picker"

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local themes = require "telescope.themes"

local insert_text = function(name)
  return function()
    vim.schedule(function()
      vim.cmd.startinsert()
      vim.api.nvim_feedkeys(" " .. name, "n", true)
    end)
  end
end

local get_and_insert_text = function()
  local name = vim.fn.input "Enter the name of the link: "
  vim.schedule(function()
    vim.cmd.startinsert()
    vim.api.nvim_feedkeys(" " .. name, "n", true)
  end)
end

local selections = {
  Issue = insert_text "Issue",
  ["Pull Request"] = insert_text "PR",
  Discussion = insert_text "Discussion",
  Search = get_and_insert_text,
}

local selection_names = {}
for name, _ in pairs(selections) do
  table.insert(selection_names, name)
end

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

local function pick_selection()
  local opts = vim.deepcopy(dropdown_opts)
  pickers
    .new(opts, {
      finder = finders.new_table {
        results = selection_names,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
            func = selections[entry],
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
          selection.func()
        end)
        return true
      end,
    })
    :find()
end

vim.keymap.set("i", "<C-l>", function()
  pick_selection()
end, { noremap = true, silent = true })
