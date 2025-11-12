--- Keep track of recent repositories and provide callbacks for creating issues
local gh = require "octo.gh"
local utils = require "octo.utils"

local M = {}

M.recent_repos = {}
M.max_repos = 10
M.callbacks = {}

--- Get the data directory for storing recent repos
local get_data_dir = function()
  local config_dir = vim.fn.stdpath "data"
  local plugin_dir = config_dir .. "/recent_repos"

  if vim.fn.isdirectory(plugin_dir) == 0 then
    vim.fn.mkdir(plugin_dir, "p")
  end

  return plugin_dir
end

--- Read JSON from a file
local read_json = function(file_path)
  local file = io.open(file_path, "r")

  if not file then
    return {}
  end

  local content = file:read "*a"
  file:close()

  if content == "" then
    return {}
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("Failed to parse JSON: " .. data, vim.log.levels.ERROR)
    return {}
  end

  return data
end

--- Write JSON to a file
local write_json = function(file_path, data)
  local file = io.open(file_path, "w")

  if not file then
    vim.notify(
      "Failed to open file for writing: " .. file_path,
      vim.log.levels.ERROR
    )
    return false
  end

  local ok, encoded = pcall(vim.json.encode, data)
  if not ok then
    vim.notify("Failed to encode JSON: " .. encoded, vim.log.levels.ERROR)
    return false
  end

  file:write(encoded)
  file:close()
  return true
end

--- Add a repository to the recent list
---@param name string Repository name (e.g., "owner/repo")
---@param url string Repository URL
---@param description string|nil Optional description
function M.add_repository(name, url, description)
  description = description or ""

  local repo = {
    name = name,
    url = url,
    description = description,
    timestamp = os.time(),
  }

  -- Remove if already exists (to move it to front)
  M.recent_repos = vim.tbl_filter(function(r)
    return r.name ~= name
  end, M.recent_repos)

  -- Add to front
  table.insert(M.recent_repos, 1, repo)

  -- Trim to max_repos
  if #M.recent_repos > M.max_repos then
    local trimmed = {}
    for i = 1, M.max_repos do
      table.insert(trimmed, M.recent_repos[i])
    end
    M.recent_repos = trimmed
  end

  -- Persist to disk
  write_json(get_data_dir() .. "/recent_repos.json", M.recent_repos)
end

--- Get recent repositories
---@param limit number|nil Optional limit on number of repos to return
---@return table List of repository tables
function M.get_recent_repositories(limit)
  limit = limit or #M.recent_repos

  local result = {}
  for i = 1, math.min(limit, #M.recent_repos) do
    table.insert(result, M.recent_repos[i])
  end

  return result
end

--- Register a callback for issue creation
---@param callback function Function to call when creating an issue
function M.register_callback(callback)
  if type(callback) ~= "function" then
    vim.notify("Callback must be a function", vim.log.levels.ERROR)
    return
  end

  -- Check if callback already exists
  for _, cb in ipairs(M.callbacks) do
    if cb == callback then
      return
    end
  end

  table.insert(M.callbacks, callback)
end

--- Create an issue for a repository by invoking all registered callbacks
---@param repo_name string Name of the repository
---@param issue_title string Title for the issue
---@param issue_body string|nil Body content for the issue
---@return table List of results from all callbacks
function M.create_issue_for_repository(repo_name, issue_title, issue_body)
  issue_body = issue_body or ""

  -- Find the repository
  local repo = nil
  for _, r in ipairs(M.recent_repos) do
    if r.name == repo_name then
      repo = r
      break
    end
  end

  if repo == nil then
    vim.notify(
      "Repository '" .. repo_name .. "' not found in recent repositories",
      vim.log.levels.ERROR
    )
    return {}
  end

  local issue_data = {
    repository = repo,
    title = issue_title,
    body = issue_body,
  }

  -- Call all registered callbacks
  local results = {}
  for _, callback in ipairs(M.callbacks) do
    local ok, result = pcall(callback, issue_data)
    if ok then
      table.insert(results, result)
    else
      vim.notify(
        "Callback failed: " .. tostring(result),
        vim.log.levels.ERROR
      )
    end
  end

  return results
end

--- Clear all registered callbacks
function M.clear_callbacks()
  M.callbacks = {}
end

--- Clear all repositories
function M.clear_repositories()
  M.recent_repos = {}
  write_json(get_data_dir() .. "/recent_repos.json", M.recent_repos)
end

--- Add the current repository to recent repos
local add_current_repo = function()
  gh.repo.view {
    json = "nameWithOwner,url,description",
    jq = "{name: .nameWithOwner, url: .url, description: .description}",
    opts = {
      cb = gh.create_callback {
        success = function(data)
          local repo_data = vim.fn.json_decode(data)
          M.add_repository(
            repo_data.name,
            repo_data.url,
            repo_data.description or ""
          )
        end,
        failure = function() end,
      },
    },
  }
end

--- Show recent repositories in a picker
function M.show_recent_repositories()
  local repos = M.get_recent_repositories()

  if #repos == 0 then
    vim.notify("No recent repositories", vim.log.levels.INFO)
    return
  end

  vim.ui.select(repos, {
    prompt = "Recent Repositories:",
    format_item = function(repo)
      return repo.name .. " - " .. repo.description
    end,
  }, function(choice)
    if choice then
      vim.notify("Selected: " .. choice.name)
      -- You could add navigation or other actions here
    end
  end)
end

--- Create an issue for a recent repository interactively
function M.create_issue_interactive()
  local repos = M.get_recent_repositories()

  if #repos == 0 then
    vim.notify("No recent repositories", vim.log.levels.INFO)
    return
  end

  vim.ui.select(repos, {
    prompt = "Select repository to create issue:",
    format_item = function(repo)
      return repo.name
    end,
  }, function(choice)
    if not choice then
      return
    end

    vim.ui.input({ prompt = "Issue title: " }, function(title)
      if not title or title == "" then
        return
      end

      vim.ui.input({ prompt = "Issue body (optional): " }, function(body)
        local results =
          M.create_issue_for_repository(choice.name, title, body or "")
        vim.notify(
          "Created issue with " .. #results .. " callback(s)",
          vim.log.levels.INFO
        )
      end)
    end)
  end)
end

--- Register a default callback that uses Octo to create issues
local register_default_callback = function()
  M.register_callback(function(issue_data)
    local repo = issue_data.repository
    local owner, name = unpack(vim.split(repo.name, "/"))

    -- Use Octo to create the issue
    vim.cmd(
      string.format(
        "Octo issue create %s/%s",
        owner,
        name
      )
    )

    -- Pre-fill the title if possible
    vim.schedule(function()
      vim.fn.feedkeys(
        vim.api.nvim_replace_termcodes("i", true, false, true),
        "n"
      )
      vim.fn.feedkeys(issue_data.title, "n")
    end)

    return { status = "created", repo = repo.name }
  end)
end

-- Initialize on VimEnter
local group = vim.api.nvim_create_augroup("RecentRepos", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    M.recent_repos = read_json(get_data_dir() .. "/recent_repos.json")
    register_default_callback()
    
    -- Add current repo if in a git directory
    local git_dir = vim.fn.finddir(".git", ".;")
    if git_dir ~= "" then
      add_current_repo()
    end
  end,
})

-- Create user commands
vim.api.nvim_create_user_command("RecentRepos", M.show_recent_repositories, {})
vim.api.nvim_create_user_command(
  "CreateIssueForRepo",
  M.create_issue_interactive,
  {}
)
vim.api.nvim_create_user_command("ClearRecentRepos", M.clear_repositories, {})

return M
