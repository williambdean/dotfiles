--- Zoxide picker
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local actions_state = require "telescope.actions.state"
local actions = require "telescope.actions"

local M = {}

local zoxide_query = function(prompt)
  local result = vim.fn.system("zoxide query " .. prompt .. " --list")
  return vim.split(result, "\n")
end

M.picker = function(cb)
  local opts = {}

  opts.prompt_title = "Zoxide prompt"
  opts.results_title = "Results"

  pickers
    .new(opts, {
      finder = finders.new_dynamic {
        fn = zoxide_query,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(_, map)
        map("i", "<CR>", function(prompt_bufnr)
          local selection = actions_state.get_selected_entry(prompt_bufnr)
          actions.close(prompt_bufnr)
          cb(selection.value)
        end)
        return true
      end,
    })
    :find()
end

return M
