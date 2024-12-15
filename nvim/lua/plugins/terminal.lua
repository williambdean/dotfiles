-- Taken from TJ DeVries' video on terminals in neovim
-- https://www.youtube.com/watch?v=ooTcnx066Do

local function get_query_path(file_name)
  -- Get the current Neovim config directory (relative path)
  local config_dir = vim.fn.stdpath("config")

  -- Concatenate with the relative path to your Treesitter query file
  local query_path = config_dir .. "/after/queries/python/" .. file_name

  -- Return the expanded full path
  return vim.fn.expand(query_path)
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
  for _, node in query:iter_captures(root, bufnr, 0, -1) do
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

local job_id = 0

local function open_terminal()
  vim.cmd.vnew()
  vim.cmd.term()

  job_id = vim.bo.channel
end

-- Create a small terminal
vim.keymap.set("n", "<leader>st", function()
  open_terminal()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 10)
end)

local function send_command(command)
  vim.fn.chansend(job_id, { command .. "\r\n" })
end

--Run the test in the current file
--@param args table
--@param test_name string
local function run_test(args, test_name)
  local file_path = vim.fn.expand("%:p")
  local test_command = "pytest " .. file_path
  if test_name then
    test_command = test_command .. " -k " .. test_name
  end

  if args and args.args and args.args ~= "" then
    test_command = test_command .. " " .. args.args
  end

  open_terminal()
  vim.cmd.wincmd("L")
  send_command(test_command)
end

vim.api.nvim_create_user_command("RunTest", function(args)
  local test_name = get_test_name()
  if test_name == nil then
    vim.notify("No test found", vim.log.levels.ERROR)
    return
  end

  run_test(args, test_name)
end, { nargs = "*" })
vim.api.nvim_create_user_command("RunTests", run_test, { nargs = "*" })

return {}
