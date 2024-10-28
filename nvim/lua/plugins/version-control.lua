local _, Job = pcall(require, "plenary.job")

---@brief Creates an issue on GitHub using GitHub CLI
---@param title string
---@param body string
local function create_issue(title, body)
  if not Job then
    return
  end

  body = body or ""

  Job:new({
    enable_recording = true,
    command = "gh",
    args = { "issue", "create", "--title", title, "--body", body },
    on_exit = vim.schedule_wrap(function()
      print("Created issue: " .. title)
    end),
  }):start()
end

local function get_visual_lines()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  -- Extract the lines between these positions
  return vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
end

local function create_issues()
  local lines = get_visual_lines()

  for _, line in ipairs(lines) do
    -- I want to seperate the line into title and body where the separation is the ":" character. If there is
    -- no ":" character, then the whole line is the title
    -- Example: "Title: Body" -> title = "Title", body = "Body"
    -- Example: "Title" -> title = "Title", body = ""
    -- Example: "Title: Body: More body" -> title = "Title", body = "Body: More body"
    -- Example: "Title: Body: More body: Even more body" -> title = "Title", body = "Body: More body: Even more body"
    local title, body = line:match("^(.-):%s*(.*)$")
    if not title then
      title = line
      body = ""
    end
    create_issue(title, body)
  end
end

-- Add mapping to create issues when in visual selection
vim.keymap.set("v", "<leader>ic", create_issues, { silent = false })

local function search()
  local repo = require("octo.utils").get_remote_name()

  local cmd = ":Octo search repo:" .. repo .. " "
  vim.fn.feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n")
end

vim.keymap.set("n", "<leader>os", search, { silent = true })

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

  return
end

return {
  { "tpope/vim-fugitive" },
  -- { "airblade/vim-gitgutter" },
  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gitlinker").setup({})
    end,
  },
  {
    "petertriho/cmp-git",
    dependencies = { "hrsh7th/nvim-cmp" },
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
    -- "cwntester/octo.nvim",
    dir = "~/GitHub/octo.nvim",
    config = function()
      require("octo").setup({
        -- default_to_projects_v2 = true,
        use_local_fs = false,
        enable_builtin = true,
        users = "mentionable",
        timeout = 15000,
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
              vim.fn.setreg("*", hash)
            end)
            return true
          end,
        })
      end, { silent = true })

      vim.keymap.set("n", "<leader>oo", "<CMD>Octo<CR>", { silent = true })
      vim.keymap.set(
        "n",
        "<leader>ic",
        "<CMD>Octo issue create<CR>",
        { silent = true }
      )
      vim.keymap.set("i", "@", "@<C-x><C-o>", { buffer = true, silent = true })
      vim.keymap.set("i", "#", "#<C-x><C-o>", { silent = true, buffer = true })
      vim.keymap.set(
        "n",
        "<leader>op",
        "<CMD>Octo pr list<CR>",
        { silent = true }
      )
      vim.keymap.set(
        "n",
        "<leader>oi",
        "<CMD>Octo issue list<CR>",
        { silent = true }
      )
      vim.keymap.set(
        "n",
        "<leader>od",
        "<CMD>Octo discussion list<CR>",
        { silent = true }
      )
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
