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

  Job
    :new({
      command = executable,
      args = { "-c", code },
      on_exit = vim.schedule_wrap(function(j_self, _, exit_code)
        local output = table.concat(j_self:result(), "\n")
        local stderr = table.concat(j_self:stderr_result(), "\n")
        if exit_code ~= 0 then
          vim.api.nvim_err_writeln(
            "Error executing Python code: "
              .. (stderr ~= "" and stderr or output)
          )
        else
          callback(output, stderr)
        end
      end),
    })
    :start()
end

local code_block_queries = {
  markdown = [[
    (fenced_code_block
      (info_string (language) @language)
      (code_fence_content) @code_block)
  ]],
  octo = [[
    (fenced_code_block
      (info_string (language) @language)
      (code_fence_content) @code_block)
  ]],
}

local get_code_in_code_block = function()
  local filetype = vim.bo.filetype
  local query_str = code_block_queries[filetype]

  local ok, query = pcall(vim.treesitter.query.parse, filetype, query_str)
  if not ok or not query then
    ok, query =
      pcall(vim.treesitter.query.parse, "markdown", code_block_queries.markdown)
    if not ok or not query then
      return { code = nil, language = nil, range = nil }
    end
    filetype = "markdown"
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, filetype)
  if not parser then
    return { code = nil, language = nil, range = nil }
  end

  local root = parser:parse()[1]:root()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1] - 1

  local code_block_node = nil
  local language_node = nil

  for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
    local name = query.captures[id]
    if name == "language" then
      language_node = node
    elseif name == "code_block" then
      local start_row, _, end_row, _ = node:range()
      if cursor_row >= start_row and cursor_row <= end_row then
        code_block_node = node
      end
    end
  end

  if not code_block_node then
    return {
      code = nil,
      language = nil,
      range = nil,
    }
  end

  local start_row, _, end_row, _ = code_block_node:range()
  local language = language_node
      and vim.treesitter.get_node_text(language_node, bufnr)
    or "text"

  return {
    code = vim.treesitter.get_node_text(code_block_node, bufnr),
    language = language,
    range = {
      start = start_row,
      stop = end_row,
    },
  }
end

local highlight_range = function(range, timeout)
  timeout = timeout or 250

  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace "execute_code_highlight"

  for i = range.start, range.stop do
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Search", i, 0, -1)
  end

  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  end, timeout)
end

M.copy_output_to_clipboard = function()
  local code_details = get_code_in_code_block()
  local code = code_details.code
  local language = code_details.language

  if not code then
    return
  end

  highlight_range(code_details.range, 250)

  local function handle_output(output)
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
  end

  if language == "bash" or language == "sh" or language == "terminal" then
    Job:new({
      command = "bash",
      args = { "-c", code },
      on_exit = vim.schedule_wrap(function(j_self, _, exit_code)
        local output = table.concat(j_self:result(), "\n")
        local stderr = table.concat(j_self:stderr_result(), "\n")
        if exit_code ~= 0 then
          vim.api.nvim_err_writeln(
            "Error executing shell command: "
              .. (stderr ~= "" and stderr or output)
          )
        else
          handle_output(output)
        end
      end),
    }):start()
  elseif language == "zsh" then
    Job:new({
      command = "zsh",
      args = { "-c", code },
      on_exit = vim.schedule_wrap(function(j_self, _, exit_code)
        local output = table.concat(j_self:result(), "\n")
        local stderr = table.concat(j_self:stderr_result(), "\n")
        if exit_code ~= 0 then
          vim.api.nvim_err_writeln(
            "Error executing zsh command: "
              .. (stderr ~= "" and stderr or output)
          )
        else
          handle_output(output)
        end
      end),
    }):start()
  elseif language == "python" or language == "py" then
    M.async(code, handle_output)
  elseif language == "lua" then
    local nvim_path = vim.fn.exepath "nvim"
    if nvim_path == "" then
      vim.notify(
        "Could not find nvim executable",
        vim.log.levels.ERROR,
        { title = "Execute Code" }
      )
      return
    end

    local config_path = vim.fn.stdpath "config"
    local tmpfile = vim.fn.tempname() .. ".lua"
    vim.fn.writefile(vim.split(code, "\n"), tmpfile)

    Job:new({
      command = nvim_path,
      args = { "-u", config_path .. "/init.lua", "-l", tmpfile },
      on_exit = vim.schedule_wrap(function(j_self, _, exit_code)
        vim.fn.delete(tmpfile)
        local output = table.concat(j_self:result(), "\n")
        local stderr = table.concat(j_self:stderr_result(), "\n")
        if exit_code ~= 0 then
          vim.api.nvim_err_writeln(
            "Error executing Lua: " .. (stderr ~= "" and stderr or output)
          )
        elseif stderr ~= "" then
          handle_output(stderr)
        else
          handle_output(output)
        end
      end),
    }):start()
  else
    vim.notify("Unsupported language: " .. language, vim.log.levels.WARN, {
      title = "Execute Code",
    })
  end
end

return M
