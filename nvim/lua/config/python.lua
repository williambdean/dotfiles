local M = {}

M.get_executable = function()
  if vim.fn.filereadable "uv.lock" == 1 then
    return "uv run python"
  else
    return vim.fn.exepath "python"
  end
end

M.has_ipython = function()
  return vim.fn.executable "ipython" == 1
end

return M
