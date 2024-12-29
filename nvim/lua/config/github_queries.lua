---Create a command to execute a GraphQL query from a file
local gh = require("octo.gh")

local sync_github_cli_query = function(query)
  local output = gh.run({
    args = {
      "api",
      "graphql",
      "--paginate",
      "--slurp",
      "-f",
      "query=" .. query,
    },
    mode = "sync",
  })
  local resp = vim.fn.json_decode(output)
  if #resp == 1 then
    return resp[1]
  end

  return resp
end

local function execute_query(start_line, end_line)
  start_line = start_line or 0
  end_line = end_line or -1
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
  local query = table.concat(lines, "\n")
  return sync_github_cli_query(query)
end

local write_to_file = function(file, content)
  local f = io.open(file, "w")
  f:write(content)
  f:close()
end

local write_json_to_file = function(file, content)
  write_to_file(file, vim.fn.json_encode(content))
end

vim.api.nvim_create_user_command("Query", function(args)
  local start_line, end_line
  if args.range ~= 0 then
    start_line = args.line1 - 1
    end_line = args.line2
  end

  local resp = execute_query(start_line, end_line)

  local file = args.args
  if file ~= "" and file:match(".json$") then
    vim.notify("Writing response to " .. file)
    write_json_to_file(file, resp)
  else
    vim.print(resp)
  end
end, { nargs = "*", range = true })
