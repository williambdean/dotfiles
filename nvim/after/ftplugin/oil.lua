local function switch_to_test_directory()
  local oil = require "oil"
  local current_dir = oil.get_current_dir()

  if not current_dir then
    vim.notify("Could not get current directory", vim.log.levels.WARN)
    return
  end

  -- Normalize path (remove trailing slash)
  current_dir = current_dir:gsub("/$", "")

  local cwd = vim.fn.getcwd()
  if cwd:sub(-1) ~= "/" then
    cwd = cwd .. "/"
  end

  -- Get relative path from cwd
  local relative_path = current_dir:sub(#cwd + 1)

  -- Get the first directory in the path
  local first_dir = relative_path:match "^([^/]+)"

  if not first_dir then
    vim.notify("Could not determine directory structure", vim.log.levels.WARN)
    return
  end

  -- Check if we're in a tests directory
  local in_tests = first_dir == "tests"

  local target_dir
  if in_tests then
    -- Navigate from tests/ to the source directory
    -- Remove "tests/" prefix and look for the corresponding source directory
    local source_path = relative_path:gsub("^tests/?", "")

    if source_path == "" then
      -- We're at the root tests/ directory
      -- Try to navigate to common source directories
      local source_candidates = { "nvim", "src" }
      for _, candidate in ipairs(source_candidates) do
        local full_path = cwd .. candidate
        if vim.fn.isdirectory(full_path) == 1 then
          target_dir = full_path
          break
        end
      end
    else
      -- Try common source directory patterns
      local source_candidates = { source_path, "src/" .. source_path, "nvim/" .. source_path }

      for _, candidate in ipairs(source_candidates) do
        local full_path = cwd .. candidate
        if vim.fn.isdirectory(full_path) == 1 then
          target_dir = full_path
          break
        end
      end
    end

    -- If no source directory found, notify user
    if not target_dir then
      vim.notify("Could not find corresponding source directory", vim.log.levels.WARN)
      return
    end
  else
    -- Navigate from source directory to tests/
    -- Get the path after the first directory
    local subpath = relative_path:gsub("^" .. first_dir .. "/?", "")
    
    if subpath == "" then
      -- We're at a root directory like nvim/ or src/
      target_dir = cwd .. "tests"
    else
      -- Preserve the subdirectory structure
      target_dir = cwd .. "tests/" .. subpath
    end

    -- Check if tests directory exists
    if vim.fn.isdirectory(target_dir) == 0 then
      vim.notify(
        "Tests directory does not exist: " .. target_dir,
        vim.log.levels.WARN
      )
      return
    end
  end

  -- Navigate to the target directory
  oil.open(target_dir)
end

vim.keymap.set(
  "n",
  "<leader>T",
  switch_to_test_directory,
  { noremap = true, silent = true, buffer = true }
)
