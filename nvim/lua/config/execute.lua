--- Execute a block of python code
---
local python = require "config.python"
local Job = require "plenary.job"

local M = {}

M.sync = function(code)
  local executable = python.get_executable()
  local command = string.format("%s -c '%s'", executable, code)

  local result = vim.fn.system(command)

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_err_writeln("Error executing Python code: " .. result)
    return nil
  end

  return result
end

M.async = function(code, callback)
  local executable = python.get_executable()

  Job:new({
    command = executable,
    args = { "-c", code },
    on_exit = vim.schedule_wrap(function(j_self, _, _)
      local output = table.concat(j_self:result(), "\n")
      local stderr = table.concat(j_self:stderr_result(), "\n")
      if stderr ~= "" then
        vim.api.nvim_err_writeln("Error executing Python code: " .. stderr)
      end

      callback(output, stderr)
    end),
  }):start()
end

local code_block_query = [[
  (fenced_code_block
    (info_string (language) @language)
    (code_fence_content) @code_block)
]]

local get_code_in_code_block = function()
  local query = vim.treesitter.query.parse("markdown", code_block_query)
  local bufnr = vim.api.nvim_get_current_buf()
  local root = vim.treesitter.get_parser(bufnr, "markdown"):parse()[1]:root()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1] - 1 -- 0-indexed

  for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
    local name = query.captures[id]
    if name == "code_block" then
      local start_row, _, end_row, _ = node:range()
      if cursor_row >= start_row and cursor_row <= end_row then
        local language = metadata.language or "text"
        return {
          code = vim.treesitter.get_node_text(node, bufnr),
          language = language,
          range = {
            start = start_row,
            stop = end_row,
          },
        }
      end
    end
  end

  return {
    code = nil,
    language = nil,
    range = nil,
  }
end

local highlight_range = function(range, timeout)
  timeout = timeout or 250

  -- Highlight the code block
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace "execute_code_highlight"

  -- Add highlight to each line in the range
  for i = range.start, range.stop do
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Search", i, 0, -1)
  end

  -- Clear highlight after timeout ms
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  end, timeout)
end

M.copy_output_to_clipboard = function()
  local code_details = get_code_in_code_block()
  local code = code_details.code

  if not code then
    return
  end

  highlight_range(code_details.range, 250)

  M.async(code, function(output)
    if output == "" then
      vim.notify("No output from the code block.", vim.log.levels.WARN, {
        title = "Execute Code",
      })
      return
    end

    vim.fn.setreg("+", output)
    vim.notify(
      "Copied the output to clipboard (register '+')",
      vim.log.levels.INFO,
      {
        title = "Execute Code",
      }
    )
  end)
end

return M
