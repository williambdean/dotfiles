local gh = require "octo.gh"
local utils = require "octo.utils"

local get_date_of_last_release = function()
  local args = {
    "release",
    "list",
    "--limit",
    1,
    "--json",
    "publishedAt",
    "--jq",
    ".[0].publishedAt",
  }
  return gh.run {
    args = args,
    mode = "sync",
  }
end

local callback = function()
  local cmd = ":Octo search "
  local release_date = get_date_of_last_release()
  if release_date == "" then
    utils.error "No release date found"
    return
  end

  cmd = cmd .. "is:merged merged:>=" .. release_date
  local repo = utils.get_remote_name()
  if repo then
    cmd = cmd .. " repo:" .. repo
  end
  cmd = cmd .. ' -label:"no releasenotes"'
  vim.fn.feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n")
end

vim.keymap.set("n", "<leader>sr", callback, { noremap = true, silent = true })
