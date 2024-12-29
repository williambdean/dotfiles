local gh = require("octo.gh")

local execute_query = function(query)
  local output = gh.run({
    args = { "api", "graphql", "-f", "query=" .. query },
    mode = "sync",
  })
  return vim.fn.json_decode(output)
end

local function execute_file_query(start_line, end_line)
  start_line = start_line or 0
  end_line = end_line or -1
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
  local query = table.concat(lines, "\n")
  local resp = execute_query(query)
  vim.print(resp)
end

vim.api.nvim_create_user_command("Query", function(args)
  local start_line, end_line
  if args.range ~= 0 then
    start_line = args.line1
    end_line = args.line2
  else
    start_line = 0
    end_line = -1
  end
  execute_file_query(start_line, end_line)
end, { nargs = "*", range = true })
