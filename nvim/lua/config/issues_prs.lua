-- Create a floating window with Issue and PR information for the current branch
--
local gh = require "octo.gh"
local utils = require "octo.utils"

local M = {}

---@class Floating
---@param buf number
---@param win number

---@class State
---@param number number|nil
---@param floating Floating

---@return State
local create_state = function()
  return {
    number = nil,
    floating = {
      buf = -1,
      win = -1,
    },
  }
end

---@type State
local current_state = create_state()

local current_buffer = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer = _G.octo_buffers[bufnr]
  return buffer
end

local state = {
  issues = {
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

---@class IssueInfo
---@field title string
---@field number number

---@class BranchMapping
---@field pr number
---@field issues IssueInfo[]
---
---@type table<string, BranchMapping>

-- Store of the relationship between branches and issues/PRs
-- example mapping = {
--  feature_branch = {
--  pr = 123,
--  issues = {1, 2, 3},
--  },
-- }
local mapping = {}

local closing_issues_query = [[
query($owner: String!, $name: String!, $pr_number: Int!, $n_referencing: Int = 1) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $pr_number) {
      closingIssuesReferences(first: $n_referencing) {
        nodes {
          title
					number
        }
      }
    }
  }
}
]]

---Get the closing issues for a PR
---@param opts table
---@field repo string|nil
---@field number number
---@return IssueInfo[]
local closing_issues = function(opts)
  opts = opts or {}
  local n_referencing = opts.n_referencing or 10
  local repo = opts.repo or utils.get_remote_name()
  local owner, name = utils.split_repo(repo)
  local output = gh.api.graphql {
    query = closing_issues_query,
    fields = {
      owner = owner,
      name = name,
      pr_number = opts.number,
      n_referencing = n_referencing,
    },
    jq = ".data.repository.pullRequest.closingIssuesReferences.nodes",
    opts = {
      mode = "sync",
    },
  }
  return vim.fn.json_decode(output)
end

---Get the current branch
---@return string
local current_branch = function()
  return vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
end

---Get the PR associated with the current branch
---@param branch string
---@return number|nil
local pr_into_branch = function(branch)
  local stdout, stderr = gh.pr.list {
    head = branch,
    json = "number",
    jq = ".[0].number",
    opts = {
      mode = "sync",
    },
  }

  if stderr ~= "" then
    vim.notify(stderr, vim.log.levels.ERROR)
    return nil
  end

  return tonumber(vim.trim(stdout))
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
      pr = pr_into_branch(branch),
    }
  end

  return mapping[branch].pr
end
local get_issue = function()
  local branch = current_branch()

  mapping[branch] = mapping[branch] or {}
  mapping[branch].issues = mapping[branch].issues or {}

  local issues = mapping[branch].issues

  if #issues < 1 then
    utils.error "No issues associated with the current branch"
    return
  end

  if mapping[branch] ~= nil and mapping[branch].issues ~= nil then
    return mapping[branch].issues
  end

  --- TODO: refine this logic to efficiently get the issue number
  if mapping[branch] == nil then
    get_pr()
  end

  if mapping[branch].issues == nil then
    local pr_number = get_pr()
    if pr_number == nil then
      return nil
    end

    mapping[branch].issues = closing_issues { number = pr_number }
  end

  return mapping[branch].issues
end

local hide_current = function()
  local win = current_state
  if vim.api.nvim_win_is_valid(win.floating.win) then
    vim.api.nvim_win_hide(win.floating.win)
  end
end

local hide = function(kind)
  local win = state[kind]
  if vim.api.nvim_win_is_valid(win.floating.win) then
    vim.api.nvim_win_hide(win.floating.win)
  end
end

local hide_pr = function()
  hide "pull_request"
end

local hide_issue = function()
  hide "issue"
end

---Toggle the floating window and open the file if it's not open
local toggle = function(item, file)
  if not vim.api.nvim_win_is_valid(item.floating.win) then
    item.floating = M.create_floating_window { buf = item.floating.buf }
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
    vim.notify "No issue associated with the current branch"
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
    vim.notify "No PR associated with the current branch"
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

local number_in_table = function(number, table)
  for _, value in ipairs(table) do
    if value == number then
      return true
    end
  end
  return false
end

M.mark = function()
  local buffer = current_buffer()

  if buffer == nil then
    utils.error "No Octo buffer found"
    return
  end

  local number = buffer.node.number
  local branch = current_branch()

  mapping[branch] = mapping[branch] or {}

  if buffer:isPullRequest() then
    if not utils.is_blank(mapping[branch].pr) then
      utils.error "PR already marked"
      return
    end
    mapping[branch].pr = number
  elseif buffer:isIssue() then
    mapping[branch].issues = mapping[branch].issues or {}
    local numbers = vim.tbl_map(function(issue)
      return issue.number
    end, mapping[branch].issues)
    if number_in_table(number, numbers) then
      utils.error "Issue already marked"
      return
    end
    table.insert(
      mapping[branch].issues,
      { number = number, title = buffer.node.title }
    )
  end
end

M.pick_issue = function()
  local branch = current_branch()

  local issues = mapping[branch].issues or {}

  if #issues < 1 then
    utils.error "No issues associated with the current branch"
    return
  end

  local toggle_issue = function()
    hide_current()
    state = create_state()
  end

  require("config.easy_picker").new(issues, {
    selected_callback = function(selected)
      vim.print(vim.inspect(selected))
    end,
    create_value = function(entry)
      return entry.title
    end,
  })
end

vim.api.nvim_create_user_command("Issue", M.pick_issue, {})
vim.api.nvim_create_user_command("PR", M.toggle_pr, {})
vim.api.nvim_create_user_command("Debug", M.show_state, {})
vim.api.nvim_create_user_command("Mark", M.mark, {})

return M
