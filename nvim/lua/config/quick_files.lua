--- Quickly navigate to set of files that are used for various purposes
local M = {}

local defaults = {
  width = 0.80,
  height = 0.80,
}

--- Create a floating window
--- @param opts table
--- @return table
function M.create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * defaults.width)
  local height = opts.height or math.floor(vim.o.lines * defaults.height)

  -- Calculate the position to center the window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 3)

  -- Create a buffer
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  end

  -- Define window configuration
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal", -- No borders or extra UI elements
    border = "rounded",
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

---Toggle the floating window and open the file if it's not open
local create_toggle = function(state)
  return function(file)
    if not vim.api.nvim_win_is_valid(state.win) then
      state = M.create_floating_window { buf = state.buf }
      local current_file = vim.api.nvim_buf_get_name(state.buf)
      if current_file ~= file then
        vim.cmd.edit(file)
      end
    else
      -- Save the buffer before hiding the window
      if vim.api.nvim_buf_get_option(state.buf, "modified") then
        vim.api.nvim_buf_call(state.buf, function()
          vim.cmd "write"
        end)
      end
      vim.api.nvim_win_hide(state.win)
    end

    return state
  end
end

-- Function to toggle file in a vertical split
local function create_toggle_file_in_vsplit(file)
  return function()
    local current_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local notes_bufnr = -1

    for _, win in ipairs(wins) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname:match(file .. "$") then
        notes_bufnr = bufnr
        vim.api.nvim_win_close(win, true)
        return
      end
    end

    if notes_bufnr == -1 then
      vim.cmd("rightbelow vsplit " .. file)
      vim.cmd "wincmd l" -- Move to the newly created split
    end
  end
end

local create_file_toggle = function(file)
  local state = {
    buf = -1,
    win = -1,
  }
  local toggle = create_toggle(state)
  return function()
    toggle(file)
  end
end

local toggles = {
  {
    mapping = "<leader>N",
    file = "note.md",
    toggle = create_file_toggle,
  },
  {
    mapping = "<leader>I",
    file = "issues.md",
    toggle = create_file_toggle,
  },
  {
    mapping = "<leader><leader>",
    file = require("config.obsidian").file_name "todo.md",
    toggle = create_file_toggle,
  },
  {
    mapping = "<leader>P",
    file = "script.py",
    toggle = create_toggle_file_in_vsplit,
  },
}
for _, toggle in ipairs(toggles) do
  vim.keymap.set(
    "n",
    toggle.mapping,
    toggle.toggle(toggle.file),
    { noremap = true, silent = true, desc = "Toggle " .. toggle.file }
  )
end

vim.api.nvim_create_user_command("QuickFile", function()
  vim.ui.select(toggles, {
    prompt = "Select a file: ",
    format_item = function(entry)
      return entry.file
    end,
  }, function(selected)
    vim.cmd.edit(selected.file)
  end)
end, {})

return M
