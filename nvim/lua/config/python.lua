local M = {}

---Checks if the current directory has a `uv.lock` file, indicating that it is a Uv project.
---@return boolean
M.has_uv = function()
  return vim.fn.filereadable "uv.lock" == 1
end

---Returns the path to the Python executable.
---@return string
M.get_executable = function()
  if M.has_uv() then
    return "uv run python"
  end

  local path = vim.fn.exepath "python"

  if path == "" then
    return "python"
  end

  if path:sub(1, 1) ~= "/" then
    path = "/" .. path
  end

  return path
end

---Checks if the current directory has an `ipython` executable available.
---@return boolean
M.has_ipython = function()
  return vim.fn.executable "ipython" == 1
end

return M
