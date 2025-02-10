--- Creates an issue on GitHub using GitHub CLI
-- @param opts A table containing the title and body of the issue.
local function create_issue(opts)
  local title = opts.title
  local body = opts.body or ""

  local gh = require "octo.gh"
  local gh_utils = require "octo.utils"

  local cb = function(_, stderr)
    if stderr and stderr ~= "" then
      gh_utils.error(stderr)
      return
    end

    vim.notify("Created issue: " .. title)
  end

  gh.issue.create {
    title = title,
    body = body,
    opts = {
      cb = cb,
    },
  }
end

vim.api.nvim_create_user_command("CreateIssue", function(opts)
  local start = opts.line1 - 1
  local stop = opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, start, stop, false)

  if #lines == 0 then
    vim.notify "No lines selected"
    return
  end

  local title = lines[1]
  local body = table.concat(lines, "\n", 2)
  -- Remove any leading or trailing whitespace
  title = vim.trim(title)
  body = vim.trim(body)

  create_issue { title = title, body = body }
end, { range = true })

local remove_visual_selection = function()
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
    "n",
    false
  )
end

local create_reference_issue = function(args)
  local title = vim.fn.input "Issue Title: "
  local body = vim.fn.input "Body: "
  body = body .. "\n\n" .. args
  body = vim.trim(body)
  create_issue { title = title, body = body }
  remove_visual_selection()
end

local has_upstream = function()
  local output = vim.fn.system "git remote -v"
  local lines = vim.split(output, "\n")

  for _, line in ipairs(lines) do
    if vim.startswith(line, "upstream") then
      return true
    end
  end
  return false
end

---Create reference issue
vim.keymap.set("v", "<leader>cri", function()
  require("gitlinker").link {
    action = create_reference_issue,
    message = false,
    remote = has_upstream() and "upstream" or "origin",
  }
end, {})

vim.api.nvim_create_user_command("CloseIssue", function(opts)
  require("config.close-issue").close_issue()
end, {})

local function current_buffer()
  local utils = require "octo.utils"

  local bufnr = vim.api.nvim_get_current_buf()
  local buffer = octo_buffers[bufnr]

  if not buffer then
    utils.error "Not in an octo buffer"
    return
  end

  return buffer
end

vim.keymap.set("n", "<leader>B", function()
  local buffer = current_buffer()
  vim.print(buffer)
end, { silent = true })

local function current_author()
  local utils = require "octo.utils"

  local bufnr = vim.api.nvim_get_current_buf()
  local buffer = octo_buffers[bufnr]

  if not buffer then
    utils.error "Not in an octo buffer"
    return
  end

  local author = buffer.node.author.login
  vim.fn.setreg("+", "@" .. author)
  utils.info("Copied author to clipboard: " .. author)
end

vim.keymap.set("n", "<leader>A", current_author, { silent = true })

local function search(opts)
  local cmd = ":Octo search "

  if opts.include_repo then
    local repo = require("octo.utils").get_remote_name()
    cmd = cmd .. "repo:" .. repo .. " "
  end

  vim.fn.feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n")
end

vim.keymap.set("n", "<leader>os", function()
  search { include_repo = true }
end, { silent = true, desc = "GitHub search for the current repository" })
vim.keymap.set("n", "<leader>oS", function()
  search { include_repo = false }
end, { silent = true, desc = "GitHub search" })

local function is_issue(number)
  local repo = require("octo.utils").get_remote_name()

  local cmd = string.format(
    "gh api repos/%s/issues/%d --jq '.pull_request'",
    repo,
    number
  )

  local result = vim.fn.system(cmd):gsub("^%s*(.-)%s*$", "%1")

  return result == ""
end

local function open_github_as_octo_buffer()
  local utils = require "octo.utils"
  local word = vim.fn.expand "<cWORD>"

  local match_string = "https://github.com/([%w-]+)/([%w-.]+)/(%w+)/(%d+)"
  local github_link = word:match(match_string)
  local number = word:match "#(%d+)"

  if not github_link and not number then
    vim.cmd [[normal! gf]]
    return
  end

  if not number then
    local user, repo, type, id = word:match(match_string)
    local uri = string.format("octo://%s/%s/%s/%s", user, repo, type, id)
    vim.cmd("edit " .. uri)
    return
  end

  local get_uri
  if is_issue(number) then
    get_uri = utils.get_issue_uri
  else
    get_uri = utils.get_pull_request_uri
  end

  local uri = get_uri(number)
  vim.cmd("edit " .. uri)
end

return {
  { "akinsho/git-conflict.nvim", opts = {} },
  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gw" } },
  {
    "linrongbin16/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    cmd = { "GitLink" },
    keys = {
      {
        "<leader>gy",
        function()
          require("gitlinker").link {
            message = false,
            action = require("gitlinker.actions").clipboard,
            remote = has_upstream() and "upstream" or "origin",
          }
        end,
        desc = "Copy GitHub link",
        mode = { "n", "v" },
      },
    },
  },
  {
    "petertriho/cmp-git",
    dependencies = { "hrsh7th/nvim-cmp" },
    ft = { "gitcommit", "octo", "markdown" },
    opts = {
      -- options go here
    },
    init = function()
      table.insert(require("cmp").get_config().sources, { name = "git" })
    end,
    config = function()
      require("cmp_git").setup {
        filetypes = {
          "gitcommit",
          "octo",
          -- Based on the gh pr create popup
          "markdown",
        },
      }
    end,
  },
  {
    dir = "~/GitHub/neovim-plugins/octo.nvim",
    cmd = "Octo",
    keys = {
      { "<leader>oo", "<CMD>Octo<CR>", desc = "Open Octo" },
      { "<leader>ic", "<CMD>Octo issue create<CR>", desc = "Create issue" },
      {
        "<leader>op",
        "<CMD>Octo pr list<CR>",
        desc = "List pull requests",
      },
      { "<leader>oi", "<CMD>Octo issue list<CR>", desc = "List issues" },
      {
        "<leader>od",
        "<CMD>Octo discussion list<CR>",
        desc = "List discussions",
      },
    },
    config = function()
      require("octo").setup {
        -- default_to_projects_v2 = true,
        use_local_fs = false,
        enable_builtin = true,
        default_to_projects_v2 = true,
        users = "mentionable",
        timeout = 15000,
        notifications = {
          current_repo_only = true,
        },
        commands = {
          auth = {
            status = function()
              local gh = require "octo.gh"
              local output =
                gh.auth.status { active = true, opts = { mode = "sync" } }
              vim.notify(output)
            end,
            switch = function(user)
              local gh = require "octo.gh"

              local opts = {
                opts = { mode = "sync" },
              }
              if user then
                opts.user = user
              end
              local output = gh.auth.switch(opts)
              vim.notify(output)

              -- Change the viewer global
              local split = vim.split(output, " ")
              user = split[#split]
              vim.g.octo_viewer = user
            end,
          },
        },
        pull_requests = {
          order_by = {
            field = "UPDATED_AT",
            direction = "DESC",
          },
        },
        issues = {
          order_by = {
            field = "UPDATED_AT",
            direction = "DESC",
          },
        },
        -- picker = "fzf-lua",
        -- picker_config = {
        --     use_emojis = true,
        -- },
      }

      -- I have my cursor over a link that looks like this
      -- https://github.com/pwntester/octo.nvim/issue/1
      -- And would like to open this file locally
      -- octo://pwntester/octo.nvim/issue/1

      -- Map gf to the custom function
      vim.keymap.set("n", "gf", open_github_as_octo_buffer, { silent = true })

      -- Use telescope to find a commit hash and add it where the cursor is
      vim.keymap.set("n", "<leader>ch", function()
        require("telescope.builtin").git_commits {
          attach_mappings = function(_, map)
            map("i", "<CR>", function(bufnr)
              local value =
                require("telescope.actions.state").get_selected_entry(bufnr)
              require("telescope.actions").close(bufnr)

              local hash = value.value
              vim.fn.setreg("+", hash)
            end)
            return true
          end,
        }
      end, { silent = true })

      vim.keymap.set("i", "@", "@<C-x><C-o>", { buffer = true, silent = true })
      vim.keymap.set("i", "#", "#<C-x><C-o>", { silent = true, buffer = true })
      -- Add the key mapping only for octo filetype
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "octo",
        callback = function()
          vim.keymap.set(
            "n",
            "la",
            "<CMD>Octo label add<CR>",
            { silent = true, buffer = true }
          )
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
      "ibhagwan/fzf-lua",
    },
  },
}
