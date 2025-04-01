--- Checkout the hash under the cursor.
--- Uses fugitive to checkout the hash
---

local get_work_under_cursor = function()
  return vim.fn.expand "<cWORD>"
end

vim.api.nvim_create_user_command("CheckoutHash", function()
  local hash = get_work_under_cursor()
  if hash == nil or hash == "" then
    require("telescope.builtin").git_commits()
    return
  end

  vim.cmd("Git checkout " .. hash)
end, { range = false })
