--- Keep track of where the GitHub repositories are located

local M = {}
local gh = require "octo.gh"

M.repos = {}

local data_dir_status = function()
  local config_dir = vim.fn.stdpath "data"
  local plugin_dir = config_dir .. "/repos"

  return vim.fn.isdirectory(plugin_dir) == 1, plugin_dir
end

local get_data_dir = function()
  local exists, plugin_dir = data_dir_status()
  if not exists then
    vim.fn.mkdir(plugin_dir, "p")
  end

  return plugin_dir
end

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

local get_current_repo = function(cb)
  return gh.repo.view {
    json = "nameWithOwner",
    jq = ".nameWithOwner",
    opts = {
      cb = gh.create_callback {
        success = cb,
        failure = function() end,
      },
    },
  }
end

local populate = function()
  local current_dir = vim.fn.getcwd()
  get_current_repo(function(repo)
    if current_dir and current_dir ~= "" and M[repo] == nil then
      M.repos[repo] = current_dir
      --- write_json(get_data_dir() .. "/repos.json", M)
    end
  end)
end

local group = vim.api.nvim_create_augroup("Repos", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    M.repos = read_json(get_data_dir() .. "/repos.json")
    populate()
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = group,
  callback = function()
    write_json(get_data_dir() .. "/repos.json", M.repos)
  end,
})

function M.find(name)
  return M.repos[name]
end

vim.api.nvim_create_user_command("RepoList", function()
  print(vim.inspect(M))
end, {})

return M
