---Create a command to execute a GraphQL query from a file
local gh = require("octo.gh")
local config = require("octo.config")

---@class Query
---@field query string
---@field timeout number|nil The timeout in seconds
---@field fields table

---@param opts Query
---@return table
local sync_github_cli_query = function(opts)
  local original_timeout = config.values.timeout
  if opts.timeout then
    config.values.timeout = opts.timeout * 1000
  end

  local output = gh.graphql({
    query = opts.query,
    paginate = true,
    slurp = true,
    fields = opts.fields,
    opts = {
      mode = "sync",
    },
  })
  local resp = vim.fn.json_decode(output)

  config.values.timeout = original_timeout

  if #resp == 1 then
    return resp[1]
  end

  return resp
end

---@param start_line number|nil
---@param end_line number|nil
---@param timeout number|nil The timeout in seconds
---@param fields table
local function execute_query(start_line, end_line, timeout, fields)
  start_line = start_line or 0
  end_line = end_line or -1
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
  local query = table.concat(lines, "\n")
  return sync_github_cli_query({
    query = query,
    timeout = timeout,
    fields = fields,
  })
end

local write_to_file = function(file, content)
  local f = io.open(file, "w")
  if f == nil then
    vim.notify("Failed to open file " .. file)
    return
  end

  f:write(content)
  f:close()
end

local write_json_to_file = function(file, content)
  write_to_file(file, vim.fn.json_encode(content))
end

---@class QueryArgs
---@field file string The file to write the response to
---@field timeoout number The timeout in seconds
---@field fields table

---@param args string
---@return QueryArgs
local parse_args = function(args)
  local file = ""
  local timeout = nil
  local split = vim.split(args, " ")
  local fields = {}
  for _, arg in ipairs(split) do
    if arg:match(".json$") then
      file = arg
    elseif arg:match("--timeout") then
      timeout = tonumber(vim.split(arg, "=")[2])
    elseif args ~= "" then
      local key, value = unpack(vim.split(arg, "="))
      fields[key] = value
    end
  end
  return { file = file, timeout = timeout, fields = fields }
end

vim.api.nvim_create_user_command("Query", function(args)
  local start_line, end_line
  if args.range ~= 0 then
    start_line = args.line1 - 1
    end_line = args.line2
  end

  local query_args = parse_args(args.args)
  local resp =
    execute_query(start_line, end_line, query_args.timeout, query_args.fields)

  local file = query_args.file
  if file ~= "" then
    vim.notify("Writing response to " .. file)
    write_json_to_file(file, resp)
  else
    vim.print(resp)
  end
end, { nargs = "*", range = true })
