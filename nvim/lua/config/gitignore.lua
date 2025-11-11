---This script insert a .gitignore template into the current buffer under the cursor.
local gh = require "octo.gh"
local headers = require "octo.gh.headers"

---@param cb fun(languages: string[])
local function list_languages(cb)
  gh.api.get {
    "/gitignore/templates",
    opts = {
      cb = gh.create_callback {
        success = function(data)
          local languages = vim.json.decode(data)
          cb(languages)
        end,
      },
    },
  }
end

---@param language string
---@param cb fun(template: string)
local function query_language_template(language, cb)
  gh.api.get {
    "/gitignore/templates/{language}",
    format = { language = language },
    opts = {
      headers = { headers.raw },
      cb = gh.create_callback {
        success = function(template)
          cb(template)
        end,
      },
    },
  }
end

---@param lines string[]
local function insert_under_cursor(lines)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, current_line, current_line, false, lines)
end

local function insert_gitignore_template()
  list_languages(function(languages)
    vim.ui.select(languages, {
      prompt = "Select a gitignore template:",
    }, function(language)
      query_language_template(language, function(template)
        insert_under_cursor(vim.split(template, "\n"))
      end)
    end)
  end)
end

vim.api.nvim_create_user_command(
  "InsertGitignoreTemplate",
  insert_gitignore_template,
  {}
)
