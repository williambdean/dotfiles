--- Link a Issue, PR, or Discussion in a buffer

local gh_picker = require "octo.picker"

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local themes = require "telescope.themes"

local kind_map = {
  issue = gh_picker.issues,
  pr = gh_picker.prs,
  discussion = gh_picker.discussions,
}

-- Send the keys to link the Issue, PR, or Discussion
local selected_callback = function(selected)
  vim.schedule(function()
    vim.cmd.startinsert()
    vim.api.nvim_feedkeys(" #" .. tostring(selected.obj.number), "n", true)
  end)
end

local create_picker = function(kind)
  local picker = kind_map[kind]

  return function()
    picker { cb = selected_callback }
  end
end

local get_prompt_and_search = function()
  local opts = {
    prompt = "Enter the search query: ",
    default = "",
  }
  vim.ui.input(opts, function(prompt)
    if prompt == "" then
      return
    end
    gh_picker.search {
      prompt = prompt,
      cb = selected_callback,
    }
  end)
end

local selections = {
  Issue = create_picker "issue",
  ["Pull Request"] = create_picker "pr",
  Discussion = create_picker "discussion",
  Search = get_prompt_and_search,
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
