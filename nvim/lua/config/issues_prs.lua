-- Is the current branch a PR?
-- Is the current branch associated with an issue?
--
--
-- Floating window
-- Store off the mapping from branch to issue and PR

local M = {}

local mapping = {}

local state = {
  issue = {
    buf = -1,
    win = -1,
  },
  pull_request = {
    buf = -1,
    win = -1,
  },
}

---Get the current branch
local current_branch = function()
  return vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
end

local pr_into_branch = function(branch)
  local cmd = "gh pr list --head "
    .. branch
    .. " --json number --jq '.[0].number'"
  return vim.fn.systemlist(cmd)[1]
end

--- Create a floating window
local function create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  -- Calculate the position to center the window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- Create a buffer
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    vim.notify("Creating a new buffer")
    buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  end

  -- Define window configuration
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    -- style = "minimal", -- No borders or extra UI elements
    border = "rounded",
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

local toggle_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window({ buf = state.floating.buf })
    if vim.bo[state.floating.buf].buftype ~= "terminal" then
      vim.cmd.terminal()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

local utils = require("octo.utils")

local toggle_issue = function()
  local issue_number = 52
  local file = utils.get_issue_uri(issue_number)

  if not vim.api.nvim_win_is_valid(state.issue.win) then
    vim.notify("The floating window is not valid")

    state.issue = create_floating_window({ buf = state.issue.buf })
    if vim.bo[state.issue.buf].buftype ~= "octo" then
      vim.notify("I am here running the issue")
      vim.cmd.edit(file)
      vim.bo.filetype = "octo"
    end
  else
    vim.api.nvim_win_hide(state.issue.win)
  end
end

local toggle_pr = function()
  local pr_number = 4
  local file = utils.get_pull_request_uri(pr_number)

  if not vim.api.nvim_win_is_valid(state.pull_request.win) then
    state.pull_request =
      create_floating_window({ buf = state.pull_request.buf })
    if vim.bo[state.pull_request.buf].buftype ~= "octo" then
      vim.cmd.edit(file)
    end
  else
    vim.api.nvim_win_hide(state.pull_request.win)
  end
end

local show_state = function()
  local branch = current_branch()
  local pr = pr_into_branch(branch)
  vim.print("The current branch " .. branch)
  vim.print("The PR number")
  vim.print(pr)
  print(vim.inspect(state))
end

vim.api.nvim_create_user_command("Terminal", toggle_terminal, {})
vim.api.nvim_create_user_command("Issue", toggle_issue, {})
vim.api.nvim_create_user_command("PR", toggle_pr, {})
vim.api.nvim_create_user_command("State", show_state, {})

return M
