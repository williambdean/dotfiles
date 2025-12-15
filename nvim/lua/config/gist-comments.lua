--- Add gist comments to a gist and view existing comments

local gh = require "octo.gh"
local utils = require "octo.utils"

local buffers = {}

---@class AddCommentOpts
---@field gist_id string
---@field body string

---@param opts AddCommentOpts
local add_comment = function(opts)
  gh.api.post {
    "/gists/{gist_id}/comments",
    format = { gist_id = opts.gist_id },
    f = { body = opts.body },
    opts = { cb = gh.create_callback {} },
  }
end

---@class Gist
---@field id string
---@field description string

---@param gists Gist[]
---@param cb fun(gist: Gist?)
local select_gist = function(gists, cb)
  vim.ui.select(gists, {
    prompt = "Select a gist",
    format_item = function(item)
      local description = item.description

      if item.public then
        description = description .. " (public)"
      else
        description = description .. " (private)"
      end

      return description
    end,
  }, function(selected)
    cb(selected)
  end)
end

---@class GistComment
---@field id number
---@field created_at string
---@field body string

---Display gist comments in a new buffer
---@param comments GistComment[]
local display_gist_comments = function(comments)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local lines = {}
  for _, comment in ipairs(comments) do
    table.insert(
      lines,
      string.format("ID: %s Created: %s", comment.id, comment.created_at)
    )
    table.insert(lines, "")
    -- Split the body by newlines and add each line
    for line in comment.body:gmatch "[^\r\n]+" do
      table.insert(lines, line)
    end
    table.insert(lines, "") -- Empty line between comments
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Set buffer filetype to Markdown
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

  -- Create a vertical split and set the buffer
  vim.cmd.vsplit()
  vim.api.nvim_win_set_buf(0, bufnr)

  return bufnr
end

local get_gist_comments = function(opts)
  gh.api.get {
    "/gists/{gist_id}/comments",
    format = { gist_id = opts.gist_id },
    jq = "map({id: .id, body: .body, created_at: .created_at})",
    opts = {
      cb = gh.create_callback {
        success = function(output)
          local comments = vim.json.decode(output)
          local bufnr = display_gist_comments(comments)

          buffers[bufnr] = {
            gist_id = opts.gist_id,
            comments = comments,
          }
        end,
      },
    },
  }
end

local function list_gists(cb)
  gh.api.get {
    "/gists",
    jq = ". | map({ id: .id, description: .description, public: .public })",
    opts = {
      cb = gh.create_callback {
        success = function(output)
          ---@type Gist[]
          local gists = vim.json.decode(output)
          select_gist(gists, cb)
        end,
      },
    },
  }
end

vim.api.nvim_create_user_command("GistDebug", function()
  vim.print(vim.inspect(buffers))
end, {})

vim.api.nvim_create_user_command("ListGistComments", function(opts)
  list_gists(function(gist)
    get_gist_comments {
      gist_id = gist.id,
    }
  end)
end, {})

vim.api.nvim_create_user_command("CreateGistComment", function(opts)
  local start = opts.line1 - 1
  local stop = opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, start, stop, false)

  if #lines == 0 then
    utils.error "No lines selected"
    return
  end

  local body = vim.trim(table.concat(lines, "\n"))

  list_gists(function(gist)
    if not gist then
      utils.error "No gist selected. Aborting."
      return
    end

    vim.ui.select(
      {
        "No",
        "Yes",
      },
      { prompt = "Add comment to " .. gist.description .. "?" },
      function(choice)
        if choice ~= "Yes" then
          utils.info "Aborting comment addition"
          return
        end

        add_comment {
          gist_id = gist.id,
          body = body,
        }
        utils.info("Comment added to " .. gist.description)
      end
    )
  end)
end, { range = true })
