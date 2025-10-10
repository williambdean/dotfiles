-- Taken from TJ DeVries' video on terminals in neovim
-- https://www.youtube.com/watch?v=ooTcnx066Do
local M = {}

local function get_query_path(file_name)
  -- Get the current Neovim config directory (relative path)
  local config_dir = vim.fn.stdpath "config"

  -- Concatenate with the relative path to your Treesitter query file
  local query_path = config_dir .. "/after/queries/python/" .. file_name

  -- Return the expanded full path
  return vim.fn.expand(query_path)
end

local get_test_name = function(node, bufnr)
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
  return nil
end

local between = function(value, start, finish)
  return value >= start and value <= finish
end

function M.get_test_names(start_line, end_line)
  if end_line == nil then
    end_line = start_line
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local query = vim.treesitter.query.parse(
    "python",
    vim.fn.join(vim.fn.readfile(get_query_path "tests.scm"), "\n")
  )
  local parser = vim.treesitter.get_parser(bufnr, "python")
  local tree = parser:parse()[1]
  local root = tree:root()

  -- Find the test function containing current line
  local tests = {}

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    local sline, _, eline, _ = node:range()
    sline = sline + 1
    eline = eline + 1

    local inside_range = between(sline, start_line, end_line)
      or between(eline, start_line, end_line)
      or between(start_line, sline, eline)
      or between(end_line, sline, eline)

    -- Get the function name node (first child of type identifier)
    local test_name = get_test_name(node, bufnr)
    if test_name ~= nil and inside_range then
      table.insert(tests, {
        start_line = sline,
        end_line = eline,
        name = test_name,
      })
    end
  end

  return tests
end

local unique_items = function(items)
  local unique = {}
  for _, item in ipairs(items) do
    unique[item] = true
  end

  local result = {}
  for item, _ in pairs(unique) do
    table.insert(result, item)
  end

  return result
end

M.get_tests_in_range = function(start_line, end_line)
  local tests = M.get_test_names(start_line, end_line)
  local tests_names = {}
  for _, test in ipairs(tests) do
    table.insert(tests_names, test.name)
  end
  return unique_items(tests_names)
end

vim.api.nvim_create_user_command("GetTestNames", function(args)
  local start_line, end_line = args.line1, args.line2
  vim.print(M.get_tests_in_range(start_line, end_line))
end, { range = true })

function M.get_test_under_cursor()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  return M.get_tests_in_range(current_line, current_line)
end

M.state = {
  job_id = 0,
  open = false,
  bufnr = -1,
}

local reset_state = function()
  M.state.job_id = 0
  M.state.open = false
  M.state.bufnr = -1
end

-- Open a terminal window
-- @param right boolean
function M.open_terminal(opts)
  opts = opts or {}
  local right = opts.right or false

  if M.state.open then
    return
  end

  vim.cmd.split()
  vim.cmd.term()

  if right then
    vim.cmd "wincmd L"
  end

  M.state.job_id = vim.bo.channel
  M.state.open = true
  M.state.bufnr = vim.api.nvim_get_current_buf()

  -- Register the autocommand for the specific terminal buffer
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = M.state.bufnr,
    callback = reset_state,
  })
end

function M.send_command(command, id)
  vim.fn.chansend(id or M.state.job_id, command .. "\r\n")
end

--Run the test in the current file
--@param args table
--@param test_name string
function M.run_test(args, test_names)
  local file_path = vim.fn.expand "%:p"
  local python_executable = require("config.python").get_executable()
  if python_executable == "" then
    vim.notify("Python executable not found", vim.log.levels.ERROR)
    return
  end

  local test_command = python_executable .. " -m pytest " .. file_path

  local selected = table.concat(test_names, " or ")
  if selected ~= "" then
    test_command = test_command .. " -k '" .. selected .. "'"
  end

  if args and args.args and args.args ~= "" then
    test_command = test_command .. " " .. args.args
  end

  M.open_terminal { right = true }
  M.send_command(test_command)
end

M.run_tests = function(args)
  local start_line, end_line

  if args.range ~= 0 then
    start_line, end_line = args.line1, args.line2
  else
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    start_line, end_line = current_line, current_line
  end

  local tests = M.get_tests_in_range(start_line, end_line)
  M.run_test(args, tests)
end

vim.api.nvim_create_user_command("DRunTests", function(args)
  args.args = args.args .. " --pdb -vvv"
  return M.run_tests(args)
end, { nargs = "*", range = true })

vim.api.nvim_create_user_command(
  "RunTests",
  M.run_tests,
  { nargs = "*", range = true }
)

-- Create a small terminal
vim.keymap.set("n", "<leader>st", function()
  M.open_terminal()
  vim.cmd.wincmd "J"
  vim.api.nvim_win_set_height(0, 10)
end)

function M.get_visual_lines()
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local start_line = start_pos[2] - 1
  local end_line = end_pos[2] + 1
  return vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
end

vim.api.nvim_create_user_command("GetVisualLines", function()
  local lines = M.get_visual_lines()
  vim.notify(table.concat(lines, "\n"))
end, { range = true })

function M.get_buffer_lines()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

vim.api.nvim_create_user_command("TerminalStatus", function()
  vim.notify(vim.inspect(M.state))
end, {})

return M
