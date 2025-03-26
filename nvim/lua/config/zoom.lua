local M = {}

local zoomed = false
local wincmd = vim.cmd.wincmd

function M.zoom_toggle()
  if zoomed then
    wincmd "="
    zoomed = false
  else
    wincmd "_"
    wincmd "|"
    zoomed = true
  end
end

vim.keymap.set("n", "<leader>O", M.zoom_toggle, { noremap = true })

return M
