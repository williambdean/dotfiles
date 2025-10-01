-- Convert a visual selection Python code block into NumPy-style (>>> / ...)
-- Lines 4 spaces more than .. code-block:: python are top-level (>>>)
function CodeBlockToNumpy()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local result = {}

  local baseline_indent = ""
  -- Detect baseline indentation from ".. code-block:: python"
  while
    #lines > 0
    and (
      lines[1]:match "^%s*$" or lines[1]:match "^%s*%.%. code%-block:: python"
    )
  do
    local m = lines[1]:match "^(%s*)%.%. code%-block:: python"
    if m then
      baseline_indent = m
    end
    table.remove(lines, 1)
  end

  if #lines == 0 then
    return
  end

  local top_level_indent_len = #baseline_indent + 4

  for _, line in ipairs(lines) do
    if line:match "^%s*$" then
      table.insert(result, baseline_indent .. "...")
    else
      local leading = line:match "^(%s*)" or ""
      local content = line:gsub("^" .. leading, "")
      if #leading == top_level_indent_len then
        table.insert(result, baseline_indent .. ">>> " .. content)
      elseif #leading > top_level_indent_len then
        -- continuation line relative to top-level
        local rel_indent = leading:sub(5) -- remove 4 spaces top-level
        table.insert(result, baseline_indent .. "... " .. rel_indent .. content)
      else
        -- less than top-level (unlikely) treat as top-level anyway
        table.insert(result, baseline_indent .. ">>> " .. content)
      end
    end
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, result)
end

-- Visual mapping
vim.api.nvim_set_keymap(
  "v",
  "<leader>cn",
  ":lua CodeBlockToNumpy()<CR>",
  { noremap = true, silent = true }
)
