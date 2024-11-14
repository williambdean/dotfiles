local function switch_to_test_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(bufnr)

  -- Check if file is a Python file
  if not current_file:match("%.py$") then
    vim.notify("Not a Python file", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()

  -- Ensure cwd ends with separator
  if cwd:sub(-1) ~= "/" then
    cwd = cwd .. "/"
  end

  -- Remove cwd from the beginning of the path
  local relative_path = current_file:sub(#cwd + 1)

  local first_dir = relative_path:match("^([^/]+)/")
  local file_name = current_file:match("([^/]+)$")

  -- Check if it's in tests directory
  local in_tests = first_dir == "tests"

  if not in_tests then
    -- Replace the first directory with "tests"
    local test_file_path = current_file
      :gsub(first_dir, "tests")
      :gsub(file_name, "test_" .. file_name)
    vim.cmd("edit " .. test_file_path)
    return
  end

  local module_file_name = relative_path:gsub("test_", ""):gsub("tests/", "")

  -- Directories off of the cwd
  local directories = vim.fn.glob("./*/", true, true)

  for _, dir in ipairs(directories) do
    local module_file = dir .. module_file_name
    if vim.fn.filereadable(module_file) == 1 then
      vim.cmd("edit " .. module_file)
      return
    end
  end

  vim.notify("Could not find the module file", vim.log.levels.WARN)
end

vim.keymap.set(
  "n",
  "<leader>T",
  switch_to_test_file,
  { noremap = true, silent = true }
)

function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return lines
end

local function python_main_block()
  -- Go to the end of the file
  vim.api.nvim_command("normal! G")
  -- Insert Python main block
  vim.api.nvim_buf_set_lines(0, -1, -1, false, {
    "",
    "",
    'if __name__ == "__main__":',
    "    # TODO: write your code here",
  })
  vim.api.nvim_command("normal! G")
end

local function random_seed()
  local function add_rng_to_script(seed)
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(0, row, row, false, {
      'seed = sum(map(ord, "' .. seed .. '"))',
      "rng = np.random.default_rng(seed)",
    })
  end

  vim.ui.input({ prompt = "Seed: " }, add_rng_to_script)
end

-- Map <leader>mb to call the function
vim.keymap.set(
  "n",
  "<leader>mb",
  python_main_block,
  { noremap = true, silent = true }
)

vim.keymap.set(
  "n",
  "<leader>rs",
  random_seed,
  { noremap = true, silent = true }
)

function print_current_visual_selection()
  local lines = get_visual_selection()
  local code = table.concat(lines, "\n")
  local file = io.open("temp-python-script.py", "w")
  file:write(code)
  file:close()
  os.execute("python temp-python-script.py")
  os.remove("temp-python-script.py")
end

vim.keymap.set(
  "v",
  "<C-r>",
  ":lua print_current_visual_selection()<CR>",
  { noremap = true, silent = true }
)

return {
  {
    "jpalardy/vim-slime",
    lazy = true,
    event = { "BufReadPre *.py", "BufReadPre *.md" },
    cmd = { "SlimeConfig" },
    config = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_python_ipython = 1
      vim.g.slime_default_config = {
        socket_name = "default",
        target_pane = "{last}",
        python_ipython = 0,
        dispatch_ipython_pause = 100,
      }
      vim.g.slime_bracketed_paste = 1
    end,
  },
  -- {
  --     "hanschen/vim-ipython-cell",
  --     lazy = true,
  --     event = { "BufReadPre *.py" },
  -- },
}
