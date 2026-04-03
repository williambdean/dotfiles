--- Create GitHub Gists from the current buffer or visual selection

local gh = require "octo.gh"
local utils = require "octo.utils"

---Return a sensible default filename for the gist based on the current buffer.
---Falls back to "gist.txt" for unnamed / scratch buffers.
---@return string
local function default_filename()
  local name = vim.api.nvim_buf_get_name(0)
  if name and name ~= "" then
    return vim.fn.fnamemodify(name, ":t")
  end
  return "gist.txt"
end

---@class CreateGistOpts
---@field filename string
---@field description string
---@field public boolean
---@field content string

---@param opts CreateGistOpts
local function create_gist(opts)
  -- octo.gh's insert_input recursively expands nested tables, so:
  --   f = { files = { [filename] = { content = "..." } } }
  -- becomes:  --raw-field "files[filename][content]=..."
  -- which is exactly what the GitHub REST API expects.
  gh.api.post {
    "/gists",
    f = {
      description = opts.description,
      public = tostring(opts.public),
      files = {
        [opts.filename] = { content = opts.content },
      },
    },
    opts = {
      cb = gh.create_callback {
        success = function(output)
          local ok, gist = pcall(vim.json.decode, output)
          if not ok or not gist or not gist.html_url then
            utils.error "Gist created but failed to parse response URL"
            return
          end
          vim.fn.setreg("+", gist.html_url)
          utils.info("Gist created: " .. gist.html_url .. " (URL copied)")
        end,
      },
    },
  }
end

---Prompt the user for gist metadata then create the gist.
---@param content string The text content to publish as the gist.
local function prompt_and_create(content)
  vim.ui.input(
    { prompt = "Filename: ", default = default_filename() },
    function(filename)
      if not filename or vim.trim(filename) == "" then
        utils.info "Gist creation cancelled"
        return
      end
      filename = vim.trim(filename)

      vim.ui.input(
        { prompt = "Description (optional): " },
        function(description)
          if description == nil then
            -- User hit <Esc> — treat as cancel
            utils.info "Gist creation cancelled"
            return
          end
          description = vim.trim(description)

          vim.ui.select({ "secret", "public" }, {
            prompt = "Visibility:",
          }, function(choice)
            if not choice then
              utils.info "Gist creation cancelled"
              return
            end

            create_gist {
              filename = filename,
              description = description,
              public = choice == "public",
              content = content,
            }
          end)
        end
      )
    end
  )
end

vim.api.nvim_create_user_command("CreateGist", function(opts)
  local start = opts.line1 - 1
  local stop = opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, start, stop, false)

  if #lines == 0 then
    utils.error "No content to create gist from"
    return
  end

  local content = table.concat(lines, "\n")
  prompt_and_create(content)
end, {
  range = "%",
  desc = "Create a GitHub Gist from the current buffer or visual selection",
})
