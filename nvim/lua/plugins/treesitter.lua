-- Define a function to get the absolute path to the query file
local function get_query_path(file_name)
  -- Get the current Neovim config directory (relative path)
  local config_dir = vim.fn.stdpath("config")

  -- Concatenate with the relative path to your Treesitter query file
  local query_path = config_dir .. "/after/queries/python/" .. file_name

  -- Return the expanded full path
  return vim.fn.expand(query_path)
end

local function combine_lines(nodes)
  local combined = {}
  for _, node in ipairs(nodes) do
    if #combined == 0 then
      table.insert(combined, node)
    else
      local last = combined[#combined]
      if node.start_line == last.end_line + 1 and node.id == last.id then
        last.end_line = node.end_line
      else
        table.insert(combined, node)
      end
    end
  end
  return combined
end

local function fold_lines(lines, action)
  for _, line in ipairs(lines) do
    vim.cmd(line.start_line + 1 .. "," .. line.end_line + 1 .. action)
  end
end

-- Define custom fold functions using Treesitter
local function process_docstrings(action)
  local bufnr = vim.api.nvim_get_current_buf()
  local query = vim.treesitter.query.parse(
    "python",
    vim.fn.join(vim.fn.readfile(get_query_path("python_docstrings.scm")), "\n")
  )
  local parser = vim.treesitter.get_parser(bufnr, "python")
  local tree = parser:parse()[1]
  local root = tree:root()

  local nodes = {}
  for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
    local start_line, _, end_line, _ = node:range()
    table.insert(
      nodes,
      { start_line = start_line, end_line = end_line, id = query.captures[id] }
    )
  end
  local combined = combine_lines(nodes)
  fold_lines(combined, action)
end

local function fold_docstrings()
  process_docstrings("fold")
end

local function unfold_docstrings()
  process_docstrings("foldopen")
end

local function get_test_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local query = vim.treesitter.query.parse(
    "python",
    vim.fn.join(vim.fn.readfile(get_query_path("tests.scm")), "\n")
  )
  local parser = vim.treesitter.get_parser(bufnr, "python")
  local tree = parser:parse()[1]
  local root = tree:root()

  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Find the test function containing current line
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local start_line, _, end_line, _ = node:range()
    if current_line >= start_line and current_line <= end_line + 1 then
      -- Get the function name node (first child of type identifier)
      for child in node:iter_children() do
        if child:type() == "identifier" then
          return vim.treesitter.get_node_text(child, bufnr)
        elseif child:type() == "function_definition" then
          for grandchild in child:iter_children() do
            if grandchild:type() == "identifier" then
              return vim.treesitter.get_node_text(grandchild, bufnr)
            end
          end
        end
      end
    end
  end
  return nil
end

local function create_or_get_output_buf()
  local bufname = "TestOutput"
  -- Try to find existing buffer
  local bufnr = vim.fn.bufnr(bufname)
  if bufnr == -1 then
    -- Create new buffer if it doesn't exist
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, bufname)
  end
  return bufnr
end

local function show_output_in_buffer(output)
  local bufnr = create_or_get_output_buf()
  print("The buffer number is " .. bufnr)
  vim.bo[bufnr].modifiable = true
  -- Clear buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  -- Set buffer content
  local lines = vim.split(output, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  -- Open buffer in a split
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, bufnr)
  -- Set buffer options
  vim.bo[bufnr].filetype = "nofile"
  vim.bo[bufnr].modifiable = false
  -- Enable terminal colors
  -- vim.opt_local.termguicolors = true
  vim.bo[bufnr].filetype = "terminal"
end

--Run the test in the current file
--@param args table
--@param test_name string
local function run_test(args, test_name)
  local file_path = vim.fn.expand("%:p")
  print("The file is " .. file_path)
  local test_command = "pytest " .. file_path
  if test_name then
    test_command = test_command .. " -k " .. test_name
  end

  if args and args.args and args.args ~= "" then
    test_command = test_command .. " " .. args.args
  end
  print("The command is " .. test_command)

  local output = ""

  vim.fn.jobstart(test_command, {
    on_stdout = function(_, data)
      output = output .. table.concat(data, "\n")
    end,
    on_stderr = function(_, data)
      output = output .. table.concat(data, "\n")
    end,
    on_exit = function(_, code)
      show_output_in_buffer(output)
      if code == 0 then
        print("Test passed")
      else
        print("Test failed")
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return {
  { "powerman/vim-plugin-AnsiEsc" },
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    ft = { "python" },
    build = ":TSUpdate",
    cmd = {
      "TSUpdate",
      "TSUpdateSync",
      "FoldDocstrings",
      "UnfoldDocstrings",
    },
    keys = {
      { "ab", mode = "o" },
      { "ib", mode = "o" },
      { "af", mode = "o" },
      { "if", mode = "o" },
      { "ac", mode = "o" },
      { "ic", mode = "o" },
      { "il", mode = "o" },
      { "al", mode = "o" },
    },
    config = function()
      -- Create Neovim commands to fold/unfold docstrings
      vim.api.nvim_create_user_command("FoldDocstrings", fold_docstrings, {})
      vim.api.nvim_create_user_command(
        "UnfoldDocstrings",
        unfold_docstrings,
        {}
      )
      vim.api.nvim_create_user_command("RunTest", function(args)
        local test_name = get_test_name()
        if test_name == nil then
          print("No test found")
          return
        end

        print("Found the test " .. test_name)
        run_test(args, test_name)
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("RunTests", run_test, { nargs = "*" })

      -- Autocmd to run FoldDocstrings when entering a Python file
      local fold_docstrings_group =
        vim.api.nvim_create_augroup("FoldDocstringGroup", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          vim.cmd("FoldDocstrings")
        end,
        group = fold_docstrings_group,
      })

      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "python",
        },
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
        },
        refactor = {
          highlight_definitions = {
            enable = true,
          },
        },
        textobjects = {
          -- swap = {
          --     enable = true,
          --     swap_next = {
          --         ["<leader>a"] = "@parameter.inner",
          --     },
          --     swap_previous = {
          --         ["<leader>A"] = "@parameter.inner",
          --     },
          -- },
          select = {
            enable = true,
            keymaps = {
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["il"] = "@loop.inner",
              ["al"] = "@loop.outer",
            },
          },
        },
      })
    end,
  },
}
