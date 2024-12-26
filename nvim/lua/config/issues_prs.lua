-- Create a floating window with Issue and PR information for the current branch
local gh = require("octo.gh")
local utils = require("octo.utils")

local M = {}

local state = {
  issue = {
    number = nil,
    floating = {
      buf = -1,
      win = -1,
    },
  },
  pull_request = {
    number = nil,
    floating = {
      buf = -1,
      win = -1,
    },
  },
}

-- Store of the relationship between branches and issues/PRs
local mapping = {}

local closing_issues_query = [[
query {
  repository(owner: "%s", name: "%s") {
    pullRequest(number: %s) {
      closingIssuesReferences(first: 1) {
        nodes {
					number
        }
      }
    }
  }
}
]]

---Get the closing issue for a PR
---@param pr_number number
---@return number
local closing_issue = function(pr_number)
  local remote_name = utils.get_remote_name()
  local remote_split = vim.split(remote_name, "/")
  local owner, name = remote_split[1], remote_split[2]
  local query = string.format(closing_issues_query, owner, name, pr_number)
  local output = gh.run({
    args = { "api", "graphql", "-f", string.format("query=%s", query) },
    mode = "sync",
  })
  local resp = vim.fn.json_decode(output)
  local references =
    resp.data.repository.pullRequest.closingIssuesReferences.nodes

  if #references < 1 then
    return nil
  end

  local numbers = {}
  for _, reference in ipairs(references) do
    table.insert(numbers, reference.number)
  end

  if #numbers > 1 then
    vim.notify("Multiple issues associated with the PR. Using the first one.")
  end

  return numbers[1]
end

---Get the current branch
---@return string
local current_branch = function()
  return vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
end

---Get the PR associated with the current branch
---@param branch string
---@return number
local pr_into_branch = function(branch)
  local cmd = "gh pr list --head "
    .. branch
    .. " --json number --jq '.[0].number'"
  return vim.fn.systemlist(cmd)[1]
end

--- Create a floating window
--- @param opts table
--- @return table
function M.create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.65)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  -- Calculate the position to center the window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 3)

  -- Create a buffer
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  end

  -- Define window configuration
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal", -- No borders or extra UI elements
    border = "rounded",
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

local get_pr = function()
  local branch = current_branch()
  if mapping[branch] == nil then
    mapping[branch] = {
      pr = tonumber(pr_into_branch(branch)),
    }
  end

  return mapping[branch].pr
end
local get_issue = function()
  local branch = current_branch()

  if mapping[branch] ~= nil and mapping[branch].issue ~= nil then
    return mapping[branch].issue
  end

  --- TODO: refine this logic to efficiently get the issue number
  if mapping[branch] == nil then
    get_pr()
  end

  if mapping[branch].issue == nil then
    local pr_number = get_pr()
    mapping[branch].issue = closing_issue(pr_number)
  end

  return mapping[branch].issue
end

local hide = function(kind)
  local win = state[kind]
  if vim.api.nvim_win_is_valid(win.floating.win) then
    vim.api.nvim_win_hide(win.floating.win)
  end
end

local hide_pr = function()
  hide("pull_request")
end

local hide_issue = function()
  hide("issue")
end

---Toggle the floating window and open the file if it's not open
local toggle = function(item, file)
  if not vim.api.nvim_win_is_valid(item.floating.win) then
    item.floating = M.create_floating_window({ buf = item.floating.buf })
    local current_file = vim.api.nvim_buf_get_name(item.floating.buf)
    if current_file ~= file then
      vim.cmd.edit(file)
    end
  else
    vim.api.nvim_win_hide(item.floating.win)
  end
end

---Toggle the issue floating window
M.toggle_issue = function()
  local issue_number = get_issue()
  if issue_number == nil then
    vim.notify("No issue associated with the current branch")
    return
  end

  local file = utils.get_issue_uri(issue_number)

  hide_pr()

  local item = state.issue
  toggle(item, file)
end

---Toggle the PR floating window
M.toggle_pr = function()
  local pr_number = get_pr()
  if pr_number == nil then
    vim.notify("No PR associated with the current branch")
    return
  end
  state.pull_request.number = pr_number
  local file = utils.get_pull_request_uri(pr_number)

  hide_issue()

  local item = state.pull_request
  toggle(item, file)
end

M.show_state = function()
  vim.print(mapping)
end

vim.api.nvim_create_user_command("Issue", M.toggle_issue, {})
vim.api.nvim_create_user_command("PR", M.toggle_pr, {})
vim.api.nvim_create_user_command("Debug", M.show_state, {})

return M
