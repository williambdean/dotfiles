--- Navigation between test files and their source files
local M = {}

--- Search for a likely culprit for the module name
local find_module_path = function(module_file_name)
  local dirs = { "./*/", "./src/*/" }
  local directories = {}
  for _, dir in ipairs(dirs) do
    local results = vim.fn.glob(dir, true, true)

    for _, result in ipairs(results) do
      table.insert(directories, result)
    end
  end

  for _, dir in ipairs(directories) do
    local module_file = dir .. module_file_name
    local init_file = dir .. "__init__.py"
    if
      vim.fn.filereadable(module_file) == 1 and vim.fn.filereadable(init_file)
    then
      return module_file
    end
  end
end

M.buffer_info = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

  local cwd = vim.fn.getcwd()
  -- Ensure cwd ends with separator
  if cwd:sub(-1) ~= "/" then
    cwd = cwd .. "/"
  end

  -- Remove cwd from the beginning of the path
  local relative_path = current_file:sub(#cwd + 1)
  if relative_path:match "^src/" then
    relative_path = relative_path:sub(5)
  end

  local first_dir = relative_path:match "^([^/]+)/"
  local file_name = relative_path:match "([^/]+)$"

  -- Check if it's in tests directory
  local in_tests = first_dir == "tests"
  local test_file_path
  if not in_tests and filetype ~= "oil" then
    -- Replace the first directory with "tests"
    test_file_path = cwd
      .. relative_path
        :gsub(first_dir, "tests")
        :gsub(file_name, "test_" .. file_name)
  end

  local module_file_name
  local python_module
  if filetype ~= "oil" then
    module_file_name = relative_path:gsub("test_", ""):gsub("tests/", "")
    if in_tests then
      python_module = find_module_path(module_file_name)
    end
  end

  return {
    bufnr = bufnr,
    current_file = current_file,
    buftype = buftype,
    filetype = filetype,
    relative_path = relative_path,
    cwd = cwd,
    first_dir = first_dir,
    file_name = file_name,
    test_file_path = test_file_path,
    module_file_path = module_file_name,
    python_module = python_module,
  }
end

return M
