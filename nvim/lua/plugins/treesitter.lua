local docstrings_are_folded = {}

-- Define a function to get the absolute path to the query file
local function get_query_path(file_name)
  -- Get the current Neovim config directory (relative path)
  local config_dir = vim.fn.stdpath "config"

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
    vim.fn.join(vim.fn.readfile(get_query_path "python_docstrings.scm"), "\n")
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
  -- Needs to be a python file
  if vim.bo.filetype ~= "python" then
    vim.notify "This command only works for Python files"
    return
  end

  local bufnr = tostring(vim.api.nvim_get_current_buf())

  if docstrings_are_folded[bufnr] == nil then
    docstrings_are_folded[bufnr] = false
  end

  if docstrings_are_folded[bufnr] then
    vim.notify "The docstrings are already folded"
    return
  end

  process_docstrings "fold"
  docstrings_are_folded[bufnr] = true
end

local function unfold_docstrings()
  -- Needs to be a python file
  if vim.bo.filetype ~= "python" then
    vim.notify "This command only works for Python files"
    return
  end

  local bufnr = tostring(vim.api.nvim_get_current_buf())

  if docstrings_are_folded[bufnr] == nil then
    docstrings_are_folded[bufnr] = false
  end

  if not docstrings_are_folded[bufnr] then
    vim.notify "The docstrings are already unfolded"
    return
  end

  process_docstrings "foldopen"
  docstrings_are_folded[bufnr] = false
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

      -- Autocmd to run FoldDocstrings when entering a Python file
      local fold_docstrings_group =
        vim.api.nvim_create_augroup("FoldDocstringGroup", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          local bufnr = tostring(vim.api.nvim_get_current_buf())

          if docstrings_are_folded[bufnr] == nil then
            docstrings_are_folded[bufnr] = false
          end

          if docstrings_are_folded[bufnr] then
            return
          end

          vim.cmd "FoldDocstrings"
        end,
        group = fold_docstrings_group,
      })

      require("nvim-treesitter.configs").setup {
        ensure_installed = {
          "python",
          "graphql",
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
      }
    end,
  },
}
