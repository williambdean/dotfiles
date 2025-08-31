-- /Users/will/github/dotfiles/nvim/lua/config/github.lua
local M = {}

function M.setup()
  vim.api.nvim_create_user_command("GoToGitHubFile", function()
    local url = vim.fn.expand "<cfile>"

    if not string.match(url, "github.com") then
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("gf", true, false, true),
        "n",
        false
      )
      return
    end

    local file_path_in_repo = string.match(url, "blob/[^/]+/(.+)")
    if not file_path_in_repo then
      print "Could not parse GitHub URL."
      return
    end

    local line_number = string.match(file_path_in_repo, "#L(%d+)")
    file_path_in_repo = string.gsub(file_path_in_repo, "?plain=1", "")
    file_path_in_repo = string.gsub(file_path_in_repo, "#L%d+.*", "")

    local git_root_list = vim.fn.systemlist "git rev-parse --show-toplevel"
    if vim.v.shell_error ~= 0 or #git_root_list == 0 then
      print "Not in a git repository or git not found."
      return
    end
    local git_root = git_root_list[1]

    local full_path = git_root .. "/" .. file_path_in_repo

    if vim.fn.filereadable(full_path) == 0 then
      print("File not found: " .. full_path)
      return
    end

    vim.cmd("edit " .. full_path)
    if line_number then
      vim.cmd(line_number)
    end
  end, { nargs = 0 })
end

return M
