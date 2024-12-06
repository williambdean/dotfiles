--- Creates an issue on GitHub using GitHub CLI
-- @param opts A table containing the title and body of the issue.
local function create_issue(opts)
  local title = opts.title
  local body = opts.body

  local _, Job = pcall(require, "plenary.job")
  if not Job then
    return
  end

  body = body or ""

  Job:new({
    enable_recording = true,
    command = "gh",
    args = { "issue", "create", "--title", title, "--body", body },
    on_exit = vim.schedule_wrap(function()
      vim.notify("Created issue: " .. title)
    end),
  }):start()
end

vim.api.nvim_create_user_command("CreateIssue", function(opts)
  local start = opts.line1 - 1
  local stop = opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, start, stop, false)

  if #lines == 0 then
    vim.notify("No lines selected")
    return
  end

  local title = lines[1]
  local body = table.concat(lines, "\n", 2)
  -- Remove any leading or trailing whitespace
  title = vim.trim(title)
  body = vim.trim(body)

  create_issue({ title = title, body = body })
end, { range = true })

local function current_buffer()
  local utils = require("octo.utils")

  local bufnr = vim.api.nvim_get_current_buf()
  local buffer = octo_buffers[bufnr]

  if not buffer then
    utils.error("Not in an octo buffer")
    return
  end

  return buffer
end

vim.keymap.set("n", "<leader>B", function()
  local buffer = current_buffer()
  vim.print(buffer)
end, { silent = true })

local function current_author()
  local utils = require("octo.utils")

  local bufnr = vim.api.nvim_get_current_buf()
  local buffer = octo_buffers[bufnr]

  if not buffer then
    utils.error("Not in an octo buffer")
    return
  end

  local author = buffer.node.author.login
  vim.fn.setreg("+", "@" .. author)
  utils.info("Copied author to clipboard: " .. author)
end

vim.keymap.set("n", "<leader>A", current_author, { silent = true })

local function search()
  local repo = require("octo.utils").get_remote_name()

  local cmd = ":Octo search repo:" .. repo .. " "
  vim.fn.feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n")
end

vim.keymap.set(
  "n",
  "<leader>os",
  search,
  { silent = true, desc = "GitHub search for the current repository" }
)

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
  local utils = require("octo.utils")
  local word = vim.fn.expand("<cWORD>")

  local match_string = "https://github.com/([%w-]+)/([%w-.]+)/(%w+)/(%d+)"
  local github_link = word:match(match_string)
  local number = word:match("#(%d+)")

  if not github_link and not number then
    vim.cmd([[normal! gf]])
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
  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gw" } },
  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    -- keys = {
    --     "<leader>gy",
    --     function()
    --         require("gitlinker").get_repo_url()
    --     end,
    -- },
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
      require("cmp_git").setup({
        filetypes = {
          "gitcommit",
          "octo",
          -- Based on the gh pr create popup
          "markdown",
        },
      })
    end,
  },
  {
    dir = "~/GitHub/octo.nvim",
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
      require("octo").setup({
        -- default_to_projects_v2 = true,
        use_local_fs = false,
        enable_builtin = true,
        default_to_projects_v2 = true,
        users = "mentionable",
        timeout = 15000,
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
      })

      -- I have my cursor over a link that looks like this
      -- https://github.com/pwntester/octo.nvim/issue/1
      -- And would like to open this file locally
      -- octo://pwntester/octo.nvim/issue/1

      -- Map gf to the custom function
      vim.keymap.set("n", "gf", open_github_as_octo_buffer, { silent = true })

      -- Use telescope to find a commit hash and add it where the cursor is
      vim.keymap.set("n", "<leader>ch", function()
        require("telescope.builtin").git_commits({
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
        })
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
      -- "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
      "ibhagwan/fzf-lua",
    },
  },
}
