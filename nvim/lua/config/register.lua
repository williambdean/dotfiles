local M = {}

local info = function(message)
  vim.notify(message, vim.log.levels.INFO, {
    title = "Register Info",
  })
end

local warn = function(message)
  vim.notify(message, vim.log.levels.WARN, {
    title = "Register Warning",
  })
end

M.complete = function(arglead, cmdline, cursorpos)
  local items = {
    "edit",
    "view",
  }
  return vim.fn.filter(items, function(item)
    return vim.startswith(item, arglead)
  end)
end

local edit = function(register)
  local content = vim.fn.getreg(register)

  if content == "" then
    warn("Register " .. register .. " is empty. Please set it first.")
    return
  end

  vim.ui.input({
    prompt = "Edit content of register " .. register .. ": ",
    default = content,
  }, function(input)
    if input ~= nil then
      vim.fn.setreg(register, input)
      info("Register " .. register .. " updated with new content.")
    else
      info "Editing cancelled."
    end
  end)
end

vim.api.nvim_create_user_command("Register", function(args)
  local action = args.fargs[1]
  local register = args.fargs[2] or "*"

  if action == "edit" then
    edit(register)
  elseif action == "view" then
    info("Viewing content of register " .. register)
  end
end, {
  nargs = "*",
  complete = M.complete,
})

return M
