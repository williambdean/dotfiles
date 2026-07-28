--- Picker where table of items is passed using vim.ui.select (snacks override)
local M = {}

---@alias PickerOpts
---@field selected_callback function
---@field multi_selected_callback function
---@field close_picker boolean
---@field prompt_title string
---@field create_value function|nil
---@field preview function|nil optional function(item): preview_content

local notify = function(selected)
  vim.notify("Selected: " .. vim.inspect(selected))
end

local identity = function(x)
  return x
end

---Create a picker using vim.ui.select (snacks powered)
---@param items table
---@param opts PickerOpts
M.new = function(items, opts)
  opts = opts or {}

  opts.create_value = opts.create_value or identity
  opts.close_picker = opts.close_picker or true
  opts.prompt_title = opts.prompt_title or "Select an item"

  opts.selected_callback = opts.selected_callback or notify

  local snacks_opts = {
    preview = function(ctx)
      if opts.preview then
        return opts.preview(ctx.item.item)
      end
      if ctx.item.item then
        return {
          text = opts.create_value(ctx.item.item),
          ft = "markdown",
        }
      end
      return false
    end,
    layout = { preset = "vertical" },
  }

  vim.ui.select(items, {
    prompt = opts.prompt_title,
    format_item = function(item)
      return opts.create_value(item)
    end,
    snacks = snacks_opts,
  }, function(choice, idx)
    if choice then
      opts.selected_callback(choice)
    end
  end)
end

return M
