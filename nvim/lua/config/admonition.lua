---Picker to create admonitions in markdown files based on selected block of text
local M = {}

local kinds = {
  "NOTE",
  "TIP",
  "IMPORTANT",
  "WARNING",
  "CAUTION",
}

local function to_title_case(str)
  return str:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

local function create_admonition(kind, lines)
  local admonition = {
    "> [!" .. kind .. "]",
    ">",
  }
  for _, line in ipairs(lines) do
    table.insert(admonition, "> " .. line)
  end
  return admonition
end

local create_callback = function(start, stop, lines)
  return function(kind)
    local admonition = create_admonition(kind, lines)
    vim.api.nvim_buf_set_lines(0, start, stop, false, admonition)
  end
end

---@param opts { cb: fun(kind: string) }
local function admonition_picker(opts)
  local cb = opts.cb

  vim.ui.select(kinds, {
    prompt = "Select Admonition Type:",
    format_item = to_title_case,
  }, function(choice)
    if choice == nil then
      return
    end
    cb(choice)
  end)
end

M.picker = function(opts)
  local start = opts.line1 - 1
  local stop = opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, start, stop, false)
  admonition_picker {
    cb = create_callback(start, stop, lines),
  }
end

return M
