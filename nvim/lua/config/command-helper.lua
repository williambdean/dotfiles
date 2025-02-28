--- Command to help with CLI commands
--- Usage: :CommandHelp <command>
--- Example: :CommandHelp ls
--- Example: :CommandHelp ls -l
--- Example: :CommandHelp gh pr list
---
local set_buffer_settings = function()
  -- Create a new buffer and set the output there
  vim.cmd "setlocal filetype=help"
  vim.cmd "setlocal buftype=nofile"
  vim.cmd "setlocal bufhidden=wipe"
  vim.cmd "setlocal noswapfile"
  vim.cmd "setlocal nomodifiable"
  vim.cmd "setlocal nowrap"
  vim.cmd "setlocal nolist"
  vim.cmd "setlocal nonumber"
  vim.cmd "setlocal norelativenumber"
  vim.cmd "setlocal foldmethod=manual"
  vim.cmd "setlocal foldlevel=0"
  vim.cmd "setlocal foldcolumn=0"
  vim.cmd "setlocal foldenable"
  vim.cmd "setlocal foldminlines=1"
  vim.cmd "setlocal foldnestmax=1"
  vim.cmd "setlocal foldtext=v:lua.vim.fn.foldtext()"
  vim.cmd "setlocal foldexpr=v:lua.vim.fn.foldexpr()"
end

vim.api.nvim_create_user_command("CommandHelp", function(opts)
  local cmd

  if opts.args and opts.args ~= "" then
    cmd = opts.args
  else
    cmd = vim.fn.input "Command: "
  end

  if cmd == nil or cmd == "" then
    vim.notify("Please provide a command!", vim.log.levels.ERROR, {
      title = "Command Help",
      timeout = 500,
    })
    return
  end

  cmd = cmd .. " --help"
  local output = vim.fn.systemlist(cmd)

  if #output == 0 then
    vim.notify("No help found for " .. cmd, "error", {
      title = "Command Help",
      timeout = 500,
    })
    return
  end

  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  set_buffer_settings()
end, { range = false, nargs = "*" })
