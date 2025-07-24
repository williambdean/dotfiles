local M = {}

local function get_query_path(file_name)
  local config_dir = vim.fn.stdpath "config"
  local query_path = config_dir .. "/after/queries/python/" .. file_name
  return vim.fn.expand(query_path)
end

local function between(value, start, finish)
  return value >= start and value <= finish
end

function M.get_module_path()
  local file_path = vim.fn.expand "%:p"
  local cwd = vim.fn.getcwd()

  -- Find the position of cwd in file_path and take the substring after it
  local start_pos = file_path:find(cwd, 1, true) + #cwd + 1
  local module_path = file_path:sub(start_pos)

  -- Remove leading 'src/' if present, then format
  return module_path:gsub("^src/", ""):gsub("/", "."):gsub("%.py$", "")
end

function M.get_treesitter_context()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line, _ = unpack(vim.api.nvim_win_get_cursor(0))

  local query_content =
    vim.fn.join(vim.fn.readfile(get_query_path "context.scm"), "\n")
  local query = vim.treesitter.query.parse("python", query_content)
  local parser = vim.treesitter.get_parser(bufnr, "python")
  local tree = parser:parse()[1]
  local root = tree:root()

  local context_name = nil
  local smallest_node_size = math.huge

  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local capture_name = query.captures[id]
    if capture_name == "definition" then
      local sline, _, eline, _ = node:range()
      sline = sline + 1
      eline = eline + 1

      if between(cursor_line, sline, eline) then
        local node_size = (eline - sline)
        if node_size < smallest_node_size then
          -- Find the name node within this definition
          for child_id, child_node in
            query:iter_captures(node, bufnr, sline - 1, eline)
          do
            local child_capture_name = query.captures[child_id]
            if child_capture_name == "name" then
              context_name = vim.treesitter.get_node_text(child_node, bufnr)
              smallest_node_size = node_size
              break -- Found the name, no need to look further in this definition
            end
          end
        end
      end
    end
  end

  return context_name
end

---@param module_path string The module path derived from the file path.
---@param context_name string The name of the function or class at the cursor position.
---@param version string The version of the documentation to link to (default is "latest").
---@return string The constructed URL for the documentation.
function M.construct_url(module_path, context_name, version)
  version = version or "latest" -- Default to latest if not provided
  local url_template =
    "https://www.pymc-marketing.io/en/{version}/api/generated/{module_path}.{context_name}.html"
  local url = url_template
    :gsub("{version}", version)
    :gsub("{module_path}", module_path)
    :gsub("{context_name}", context_name)
  return url
end

function M.copy_url_to_clipboard(url)
  vim.fn.setreg("*", url)
  vim.notify("Copied to register: " .. url)
end

function M.open_url(url)
  vim.fn.system("open " .. url)
  vim.notify("Opening: " .. url)
end

function M.handle_doc_url(args)
  local action = args.fargs[1]
  local version = args.fargs[2] or "latest" -- Default to latest if not provided

  local module_path = M.get_module_path()
  if not module_path or module_path == "" then
    vim.notify("Could not determine module path.", vim.log.levels.ERROR)
    return
  end

  local context_name = M.get_treesitter_context()
  if not context_name then
    vim.notify(
      "Could not find function or class context.",
      vim.log.levels.ERROR
    )
    return
  end

  local url = M.construct_url(module_path, context_name, version)

  if action == "open" then
    M.open_url(url)
  elseif action == "copy" then
    M.copy_url_to_clipboard(url)
  else
    vim.notify(
      "Invalid action: " .. tostring(action) .. ". Use 'open' or 'copy'.",
      vim.log.levels.ERROR
    )
  end
end

return M
