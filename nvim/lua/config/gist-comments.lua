--- Add gist comments to a gist and view existing comments

local gh = require "octo.gh"
local utils = require "octo.utils"

local buffers = {}

local GIST_COMMENT_NS = vim.api.nvim_create_namespace "gist_comments"

---@class AddCommentOpts
---@field gist_id string
---@field body string
---@field cb? fun(comment: GistComment?)

---@param opts AddCommentOpts
local add_comment = function(opts)
  gh.api.post {
    "/gists/{gist_id}/comments",
    format = { gist_id = opts.gist_id },
    f = { body = opts.body },
    opts = {
      cb = gh.create_callback {
        success = function(output)
          if opts.cb then
            local comment = vim.json.decode(output)
            opts.cb(comment)
          end
        end,
      },
    },
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
---@field extmark_id? integer
---@field start_line? integer
---@field end_line? integer

---@param bufnr integer
---@return GistComment?
local get_comment_at_cursor = function(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local buffer_data = buffers[bufnr]

  if not buffer_data or not buffer_data.comments then
    return nil
  end

  for _, comment in ipairs(buffer_data.comments) do
    if comment.start_line and comment.end_line then
      if comment.start_line <= line and comment.end_line >= line then
        return comment
      end
    end
  end

  return nil
end

---@param opts { gist_id: string, comment_id: number }
local delete_comment = function(opts, cb)
  gh.api.delete {
    "/gists/{gist_id}/comments/{comment_id}",
    format = { gist_id = opts.gist_id, comment_id = opts.comment_id },
    opts = { cb = gh.create_callback { success = cb } },
  }
end

---@param bufnr integer
local delete_gist_comment = function(bufnr)
  local buffer_data = buffers[bufnr]
  if not buffer_data then
    utils.error "No gist buffer data found"
    return
  end

  local comment = get_comment_at_cursor(bufnr)
  if not comment then
    utils.error "The cursor does not seem to be located at any comment"
    return
  end

  local choice = vim.fn.confirm("Delete comment?", "&Yes\n&No\n&Cancel", 2)
  if choice ~= 1 then
    return
  end

  delete_comment({
    gist_id = buffer_data.gist_id,
    comment_id = comment.id,
  }, function()
    local start_line = comment.start_line - 1
    local end_line = comment.end_line

    vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, {})

    if comment.extmark_id then
      vim.api.nvim_buf_del_extmark(bufnr, GIST_COMMENT_NS, comment.extmark_id)
    end

    local updated = {}
    for _, c in ipairs(buffer_data.comments) do
      if c.id ~= comment.id then
        table.insert(updated, c)
      end
    end
    buffer_data.comments = updated

    utils.info "Comment deleted"
  end)
end

---@param bufnr integer
local add_gist_comment = function(bufnr)
  local buffer_data = buffers[bufnr]
  if not buffer_data then
    utils.error "No gist buffer data found"
    return
  end

  vim.ui.input({ prompt = "Comment: " }, function(body)
    if not body or vim.trim(body) == "" then
      utils.info "Aborting comment addition"
      return
    end

    add_comment {
      gist_id = buffer_data.gist_id,
      body = body,
      cb = function(comment)
        if not comment then
          utils.error "Failed to create comment"
          return
        end

        local comment_lines = {
          string.format("ID: %s Created: %s", comment.id, comment.created_at),
          "",
        }
        for line in comment.body:gmatch "[^\r\n]+" do
          table.insert(comment_lines, line)
        end
        table.insert(comment_lines, "")

        local start_line = vim.api.nvim_buf_line_count(bufnr) + 1
        vim.api.nvim_buf_set_lines(
          bufnr,
          start_line - 1,
          start_line - 1,
          false,
          comment_lines
        )

        local extmark_id = vim.api.nvim_buf_set_extmark(
          bufnr,
          GIST_COMMENT_NS,
          start_line - 1,
          0,
          {
            end_line = start_line - 1 + #comment_lines,
            end_col = 0,
          }
        )

        comment.extmark_id = extmark_id
        comment.start_line = start_line
        comment.end_line = start_line - 1 + #comment_lines
        table.insert(buffer_data.comments, comment)

        utils.info "Comment added"
      end,
    }
  end)
end

---Display gist comments in a new buffer
---@param comments GistComment[]
---@param gist_id string
local display_gist_comments = function(comments, gist_id)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local lines = {}
  for _, comment in ipairs(comments) do
    local start_line = #lines
    table.insert(
      lines,
      string.format("ID: %s Created: %s", comment.id, comment.created_at)
    )
    table.insert(lines, "")
    for line in comment.body:gmatch "[^\r\n]+" do
      table.insert(lines, line)
    end
    table.insert(lines, "")
    comment.start_line = start_line + 1
    comment.end_line = #lines

    vim.api.nvim_buf_set_extmark(bufnr, GIST_COMMENT_NS, start_line, 0, {
      end_line = #lines,
      end_col = 0,
    })
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

  vim.cmd.vsplit()
  vim.api.nvim_win_set_buf(0, bufnr)

  local gist_url = "https://gist.github.com/" .. gist_id

  vim.keymap.set("n", "ca", function()
    add_gist_comment(bufnr)
  end, { buffer = bufnr, desc = "Add comment" })

  vim.keymap.set("n", "<localleader>cd", function()
    delete_gist_comment(bufnr)
  end, { buffer = bufnr, desc = "Delete comment" })

  vim.keymap.set("n", "<C-b>", function()
    vim.ui.open(gist_url)
  end, { buffer = bufnr, desc = "Open gist in browser" })

  return bufnr
end

---@param opts { gist_id: number }
local get_gist_comments = function(opts)
  gh.api.get {
    "/gists/{gist_id}/comments",
    format = { gist_id = opts.gist_id },
    paginate = true,
    opts = {
      cb = gh.create_callback {
        success = function(output)
          local ok, comments = pcall(vim.json.decode, output)
          if not ok then
            vim.print("Raw output length: " .. #output)
            vim.print("First 500 chars: " .. string.sub(output, 1, 500))
            utils.error "Failed to parse comments response"
            return
          end
          local mapped = {}
          for _, c in ipairs(comments) do
            table.insert(mapped, {
              id = c.id,
              body = c.body,
              created_at = c.created_at,
            })
          end
          local bufnr = display_gist_comments(mapped, opts.gist_id)

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
