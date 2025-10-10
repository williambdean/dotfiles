local has_local_cargo_file = function()
  local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
  return cargo_toml ~= ""
end

local opts = {
  noremap = true,
  silent = true,
  buffer = true,
}
vim.keymap.set("n", "<leader>x", function(args)
  local filename = vim.fn.expand "%:p"
  local command
  if not has_local_cargo_file() then
    command = "rustc " .. filename .. " && " .. filename:gsub("%.rs$", "")
  else
    command = "cargo run -- " .. filename
  end

  require("config.terminal").open_terminal { right = true }
  require("config.terminal").send_command(command)
end, opts)
