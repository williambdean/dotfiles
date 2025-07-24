---Dump
local M = {}

local dump_file = nil

function M.set_dump_file()
  dump_file = vim.fn.expand "%:p"
  vim.notify("Dump file set to current file: " .. dump_file)
end

function M.dump_selection()
  if dump_file == nil then
    vim.notify("No dump file set. Use <leader>D first.", vim.log.levels.ERROR)
    return
  end

  local visual_selection = vim.fn.getreg '"'
  local file = io.open(dump_file, "a")
  if file then
    file:write(visual_selection .. "\n")
    file:close()

    -- Refresh the buffer if the dump file is currently open in a buffer
    local current_bufnr = vim.fn.bufnr(dump_file)
    if current_bufnr ~= -1 then
      vim.cmd("checktime " .. current_bufnr)
    end

    vim.notify("Selection dumped to " .. dump_file)
  else
    vim.notify("Failed to open dump file: " .. dump_file, vim.log.levels.ERROR)
  end
end

vim.keymap.set(
  "n",
  "<leader>D",
  M.set_dump_file,
  { noremap = true, desc = "Set dump file to current buffer" }
)
vim.keymap.set("v", "<leader>d", function()
  vim.cmd "normal! y"
  M.dump_selection()
end, { noremap = true, desc = "Dump selection to dump file" })

return M
