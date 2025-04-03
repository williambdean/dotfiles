--- Finds the location of obsidian file
local M = {}

local directory = [[Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/will]]
directory = vim.fn.expand("~/" .. directory)

if vim.fn.isdirectory(directory) == 0 then
  directory = vim.fn.expand("~/")
end

M.file_name = function(file_name)
  return directory .. "/" .. file_name
end

return M
