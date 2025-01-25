local M = {}

M.get_executable = function()
  return vim.fn.exepath "python"
end

M.has_ipython = function()
  return vim.fn.executable "ipython" == 1
end

return M
