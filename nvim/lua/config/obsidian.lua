--- Finds the location of obsidian file
local M = {}

local directory = [[Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/will]]
M.directory = vim.fn.expand("~/" .. directory)

M.directory_exists = vim.fn.isdirectory(M.directory) == 1

M.file_name = function(file_name)
  local directory = M.directory_exists and M.directory or vim.fn.expand("~/")
  return directory .. "/" .. file_name
end

return M
