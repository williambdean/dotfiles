local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local ts_utils = require "telescope.utils"
local defaulter = ts_utils.make_default_callable

local gh = require "octo.gh"
local utils = require "octo.utils"

local M = {}

local gen_from_release = function(opts)
  return function(entry)
    entry.repo = opts.repo

    local display = entry.name
    if entry.tagName ~= display then
      display = display .. " (" .. entry.tagName .. ")"
    end

    display = display .. " " .. utils.format_date(entry.createdAt)

    return {
      filename = utils.get_release_uri(entry.tagName, opts.repo),
      value = entry.tagName,
      display = display,
      ordinal = display,
      obj = entry,
    }
  end
end

local release_body = defaulter(function(opts)
  return previewers.new_buffer_previewer {
    title = opts.preview_title,
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,
    define_preview = function(self, entry)
      if
        self.state.bufname ~= entry.value
        or vim.api.nvim_buf_line_count(self.state.bufnr) == 1
      then
        local data = entry.obj
        if data then
          gh.release.view {
            data.tagName,
            repo = data.repo,
            json = "body",
            jq = ".body",
            opts = {
              cb = gh.create_callback {
                success = function(body)
                  vim.api.nvim_buf_set_lines(
                    self.state.bufnr,
                    0,
                    -1,
                    false,
                    vim.split(body, "\n")
                  )
                  --- wrap lines
                  vim.api.nvim_set_option_value("filetype", "markdown", {
                    scope = "local",
                    buf = self.state.bufnr,
                  })
                end,
              },
            },
          }
        end
      end
    end,
  }
end, {})

M.create_picker = function(opts)
  opts = opts or {}
  opts.repo = opts.repo or utils.get_remote_name()

  -- Create custom layout configuration
  local layout_config = {
    width = 0.8,
    height = 0.9,
    preview_width = 0.65,
  }

  -- Apply the custom layout
  -- opts = themes.get_ivy(opts)
  -- opts = themes.get_cursor(opts)
  -- opts = themes.get_dropdown(opts)
  -- opts.layout_strategy = "horizontal"
  opts.layout_config = layout_config

  gh.release.list {
    repo = opts.repo,
    json = "name,tagName,createdAt",
    opts = {
      cb = gh.create_callback {
        success = function(output)
          local results = vim.json.decode(output)

          if #results == 0 then
            local msg = "No releases found"
            if opts.repo then
              msg = msg .. " for " .. opts.repo
            else
              msg = msg .. " in the current repository"
            end
            utils.error(msg)
            return
          end

          pickers
            .new(opts, {
              finder = finders.new_table {
                results = results,
                entry_maker = gen_from_release(opts),
              },
              sorter = conf.generic_sorter(opts),
              previewer = release_body.new(opts),
              attach_mappings = function(prompt_bufnr, map)
                map("i", "<C-y>", function()
                  local selection =
                    action_state.get_selected_entry(prompt_bufnr)
                  gh.release.view {
                    selection.obj.tagName,
                    repo = selection.obj.repo,
                    json = "url",
                    jq = ".url",
                    opts = {
                      cb = gh.create_callback { success = utils.copy_url },
                    },
                  }
                  return true
                end)
                map("i", "<CR>", function()
                  local selection =
                    action_state.get_selected_entry(prompt_bufnr)
                  local repo = opts.repo
                  actions.close(prompt_bufnr)

                  utils.get("release", selection.obj.tagName, repo)

                  return true
                end)
                return true
              end,
            })
            :find()
        end,
      },
    },
  }
end

return M
