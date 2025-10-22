---This script insert a .gitignore template into the current buffer
local gh = require "octo.gh"

local insert_gitignore_template = function()
  gh.api.get {
    "/gitignore/templates",
    opts = {
      cb = gh.create_callback {
        success = function(data)
          local languages = vim.json.decode(data)
          vim.ui.select(languages, {
            prompt = "Select a gitignore template:",
          }, function(choice)
            gh.api.get {
              "/gitignore/templates/{language}",
              format = { language = choice },
              opts = {
                headers = {
                  "Accept: application/vnd.github.raw+json",
                },
                cb = gh.create_callback {
                  success = function(template)
                    local current_line = vim.api.nvim_win_get_cursor(0)[1]
                    vim.api.nvim_buf_set_lines(
                      0,
                      current_line,
                      current_line,
                      false,
                      vim.split(template, "\n")
                    )
                  end,
                },
              },
            }
          end)
        end,
      },
    },
  }
end

vim.api.nvim_create_user_command(
  "InsertGitignoreTemplate",
  insert_gitignore_template,
  {}
)
