local M = {}

function M.goto_action()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local col = cursor[2]
  local search_start = math.max(0, col - 50)
  local search_end = math.min(#line, col + 50)
  local line_portion = line:sub(search_start + 1, search_end)
  local action_repo = line_portion:match "([%w%-]+/[%w%-]+)@[^\n]+"
  if not action_repo then
    action_repo = line_portion:match "([%w%-]+/[%w%-]+)"
  end
  if not action_repo then
    action_repo = line:match "uses:%s+([%w%-]+/[%w%-]+)@[^\n]+"
  end
  if not action_repo then
    action_repo = line:match "uses:%s+([%w%-]+/[%w%-]+)"
  end
  if action_repo then
    require("octo.commands").commands.repo.view(action_repo)
  else
    require("octo.utils").error "No 'uses:' block found on this line"
  end
end

function M.setup()
  vim.keymap.set("n", "gd", function()
    local path = vim.fn.expand "%:p"
    if path:match ".github/workflows" then
      M.goto_action()
    end
  end, { buffer = true, silent = true, desc = "Go to action repo" })

  vim.keymap.set("n", "gda", function()
    M.goto_action()
  end, { buffer = true, silent = true, desc = "Go to action repo" })
end

return M
