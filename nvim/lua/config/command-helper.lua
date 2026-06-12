--- Command to help with CLI commands
--- Usage: :CommandHelp <command>
--- Example: :CommandHelp ls
--- Example: :CommandHelp ls -l
--- Example: :CommandHelp gh pr list
---
local set_buffer_settings = function()
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

local function strip_ansi(text)
  return text
    :gsub("\27[%d]*m", "")
    :gsub("\27%[%d+;%d+;%d+;%d+;%d+m", "")
    :gsub("\27%[%d+;%d+;%d+m", "")
    :gsub("\27%[%d+;%d+m", "")
    :gsub("\27%[%d+m", "")
end

local function get_help_output(cmd_args, is_uv)
  local cmd_name = cmd_args[1]

  if cmd_name == "git" and #cmd_args > 1 then
    cmd_name = "git-" .. cmd_args[2]
    cmd_args = { cmd_name }
  end

  local man_cmd = "MANWIDTH=120 man " .. cmd_name .. " 2>&1 | col -b"
  local man_result = vim.system({ "sh", "-c", man_cmd }):wait()

  local output = man_result.stdout
  if
    output:match "No manual entry"
    or output:match "command not found"
    or output:match "whatis database"
  then
    local help_args = is_uv and { "uv", "run", unpack(cmd_args) } or cmd_args
    help_args[#help_args + 1] = "--help"

    local help_result =
      vim.system(help_args, { text = true, stderr = "pipe" }):wait()
    if help_result.code ~= 0 or help_result.stdout == "" then
      return {}, nil
    end

    local help_output = vim.split(help_result.stdout, "\n")
    for i, line in ipairs(help_output) do
      help_output[i] = strip_ansi(line)
    end
    return help_output, "--help"
  end

  if man_result.code == 0 and output ~= "" then
    local lines = vim.split(output, "\n")
    return lines, "man"
  end

  local help_args = is_uv and { "uv", "run", unpack(cmd_args) } or cmd_args
  help_args[#help_args + 1] = "--help"

  local help_result =
    vim.system(help_args, { text = true, stderr = "pipe" }):wait()
  if help_result.code ~= 0 or help_result.stdout == "" then
    return {}, nil
  end

  local help_output = vim.split(help_result.stdout, "\n")
  for i, line in ipairs(help_output) do
    help_output[i] = strip_ansi(line)
  end
  return help_output, "--help"
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

  local cmd_args = vim.split(cmd, " ")
  local is_uv = false
  for i, arg in ipairs(cmd_args) do
    if arg == "--uv" then
      is_uv = true
      table.remove(cmd_args, i)
      break
    end
  end

  local output, source = get_help_output(cmd_args, is_uv)

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

  vim.notify("Displaying help from " .. source, vim.log.levels.INFO, {
    title = "Command Help",
    timeout = 500,
  })
end, { range = false, nargs = "*" })
