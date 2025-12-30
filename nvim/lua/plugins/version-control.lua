local vim = vim

--- Creates an issue on GitHub using GitHub CLI

---@param opts { title: string, body?: string } A table containing the title and body of the issue.
local function create_issue(opts)
  local title = opts.title
  local body = opts.body or ""

  local gh = require "octo.gh"
  local utils = require "octo.utils"

  local cb = gh.create_callback {
    success = function(output)
      utils.info("Created issue: " .. title)
      local answer = vim.fn.confirm("Open issue in buffer?", "&Yes\n&No", 2)
      if answer == 2 then
        return
      end
      -- Returns the URL of the issue
      -- https://github.com/wd60622/dotfiles/issues/78
      -- Return the number of the issue which is the last part
      local issue_number = output:match "issues/(%d+)$"
      vim.cmd("Octo issue edit " .. issue_number)
    end,
  }

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

---@return string[]
local function get_remotes()
  return vim.fn.systemlist "git remote"
end

---@param action fun(opts: table) The action to perform with gitlinker
local function gitlinker_link(action)
  local remotes = get_remotes()
  if #remotes == 0 then
    vim.notify("No git remotes found", vim.log.levels.ERROR)
    return
  end

  local lstart = vim.fn.line "'<"
  local lend = vim.fn.line "'>"

  if lstart == 0 or lend == 0 then
    vim.notify("No visual selection found", vim.log.levels.ERROR)
    return
  end

  local callback = function(remote)
    require("gitlinker").link {
      action = action,
      message = false,
      remote = remote,
      lstart = lstart,
      lend = lend,
    }
  end

  if #remotes == 1 then
    callback(remotes[1])
    return
  end

  vim.ui.select(remotes, {
    prompt = "There are multiple remotes. Select one:",
  }, function(remote)
    if not remote then
      return
    end
    callback(remote)
  end)
end

---Create reference issue
vim.keymap.set("v", "<leader>cri", function()
  gitlinker_link(create_reference_issue)
end, {
  desc = "Create reference issue from visual selection",
})

local function display_github_usage(decoded)
  local utils = require "octo.utils"

  local rate_limit = decoded.data.rateLimit

  local info_lines = {
    "",
    "GitHub GraphQL API Rate Limit:",
    "================================",
    string.format("Limit:     %d points per hour", rate_limit.limit),
    string.format("Used:      %d points", rate_limit.used),
    string.format("Remaining: %d points", rate_limit.remaining),
    string.format("Resets at: %s", rate_limit.resetAt),
    "",
    string.format("Usage: %.1f%%", (rate_limit.used / rate_limit.limit) * 100),
  }

  utils.info(table.concat(info_lines, "\n"))
end

vim.keymap.set("v", "<leader>gho", function()
  gitlinker_link(require("gitlinker.actions").open_in_browser)
end, {
  desc = "Open GitHub link in browser from visual selection",
})

vim.api.nvim_create_user_command("CloseIssue", function(opts)
  require("config.close-issue").close_issue()
end, {
  desc = "Close the current issue",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "octo",
  desc = "Get the current octo buffer's timeline items or full node",
  callback = function()
    vim.keymap.set("n", "<leader>B", function()
      local context = require "octo.context"
      local utils = require "octo.utils"

      context.within_octo_buffer(function(buffer)
        vim.ui.select({ "timelineItems", "full" }, {
          prompt = "Select an item",
        }, function(selected)
          local item = selected == "full" and buffer or buffer.node[selected]
          if not item then
            utils.error "No item selected"
            return
          end
          vim.notify(vim.inspect(item))
        end)
      end)()
    end, { buffer = true })
  end,
})
local function current_author()
  local utils = require "octo.utils"

  local buffer = utils.get_current_buffer()

  if not buffer then
    utils.error "Not in an octo buffer"
    return
  end

  local node = buffer:isPullRequest() and buffer:pullRequest() or buffer:issue()
  local author = node.author.login
  vim.fn.setreg("+", "@" .. author)
  utils.info("Copied author to clipboard: " .. author)
end

vim.keymap.set("n", "<leader>A", current_author, { silent = true })

vim.keymap.set("n", "<leader>os", function()
  require("octo.utils").create_base_search_command { include_current_repo = true }
end, { silent = true, desc = "GitHub search for the current repository" })
vim.keymap.set("n", "<leader>oS", function()
  require("octo.utils").create_base_search_command {
    include_current_repo = false,
  }
end, { silent = true, desc = "GitHub search" })

---@param opts { number: number, repo: string }
---@return "PullRequest"|"Issue"|"Discussion"|nil
local get_typename = function(opts)
  local gh = require "octo.gh"
  local utils = require "octo.utils"

  local query = [[
  query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      issueOrPullRequest(number: $number) {
        __typename
      }
      discussion(number: $number) {
        __typename
      }
    }
  }
  ]]

  local owner, name = utils.split_repo(opts.repo)

  local result = gh.api.graphql {
    query = query,
    F = { owner = owner, name = name, number = opts.number },
    opts = { mode = "sync" },
  }
  local repository = vim.json.decode(result).data.repository

  local issueOrPullRequest = repository.issueOrPullRequest
  if not utils.is_blank(issueOrPullRequest) then
    return issueOrPullRequest.__typename
  end

  local discussion = repository.discussion
  if not utils.is_blank(discussion) then
    return discussion.__typename
  end

  return nil
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

  local buffer = utils.get_current_buffer()
  local repo
  if buffer ~= nil and buffer.repo then
    repo = buffer.repo
  else
    repo = utils.get_remote_name()
  end

  local typename = get_typename { number = number, repo = repo }
  local get_uri = {
    Issue = utils.get_issue_uri,
    PullRequest = utils.get_pull_request_uri,
    Discussion = utils.get_discussion_uri,
  }

  get_uri = get_uri[typename]
  local uri = get_uri(number, repo)
  vim.cmd("edit " .. uri)
end

return {
  { "akinsho/git-conflict.nvim", opts = {} },
  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gw", "Gvdiffsplit" } },
  {
    "linrongbin16/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    cmd = { "GitLink" },
    keys = {
      {
        "<leader>gy",
        function()
          gitlinker_link(require("gitlinker.actions").clipboard)
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
    "lewis6991/gitsigns.nvim",
    opts = {},
    keys = {
      {
        "<leader>hq",
        function()
          local gitsigns = require "gitsigns"
          vim.ui.select({
            "buffer",
            "all",
            "attached",
          }, {
            prompt = "Select hunks to quickfix",
          }, function(choice)
            if not choice then
              return
            end

            if choice == "buffer" then
              choice = 0
            end

            gitsigns.setqflist(choice)
          end)
        end,
        desc = "GitHub Hunks to Quickfix",
      },
      {
        "]h",
        function()
          local gitsigns = require "gitsigns"
          if vim.wo.diff then
            vim.cmd.normal { "]h", bang = true }
          else
            gitsigns.nav_hunk "next"
          end
        end,
        desc = "Next GitHub Hunk",
      },
      {
        "[h",
        function()
          local gitsigns = require "gitsigns"
          if vim.wo.diff then
            vim.cmd.normal { "[h", bang = true }
          else
            gitsigns.nav_hunk "prev"
          end
        end,
        desc = "Previous GitHub Hunk",
      },
    },
  },
  {
    dir = "~/GitHub/neovim-plugins/octo.nvim",
    cmd = "Octo",
    keys = {
      {
        "<leader>oqi",
        function()
          local commands = require("octo.commands").commands

          local repos = {
            "pwntester/octo.nvim",
            "pymc-labs/pymc-marketing",
          }
          vim.ui.select(repos, {
            prompt = "Select repository to create issue in:",
          }, function(repo)
            if not repo then
              return
            end
            commands.issue.create(repo)
          end)
        end,
        desc = "Quick issue for octo.nvim",
      },
      {
        "<leader>oni",
        "<CMD>Octo issue create pwntester/octo.nvim<CR>",
        desc = "Create octo.nvim issue",
      },
      {
        "<leader>orl",
        function()
          local gh = require "octo.gh"

          gh.api.graphql {
            query = "query { rateLimit { used limit cost remaining resetAt } }",
            opts = {
              cb = gh.create_callback {
                success = function(data)
                  local decoded = vim.json.decode(data)
                  display_github_usage(decoded)
                end,
              },
            },
          }
        end,
        desc = "Octo Rate Limit",
      },
      {
        "<leader>oo",
        "<CMD>Octo<CR>",
        desc = "Open Octo",
      },
      {
        "<leader>r<leader>",
        function()
          local utils = require "octo.utils"
          local repo = utils.get_remote_name()
          require("octo.picker").notifications { repo = repo }
        end,
      },
      {
        "<leader><leader>",
        function()
          require("octo.picker").notifications { show_repo_info = false }
        end,
        desc = "GitHub Notifications",
      },
      {
        "<leader>ic",
        function()
          --- Check if in normal or visual mode
          local mode = vim.api.nvim_get_mode().mode

          if mode == "v" then
            local start = vim.fn.getpos "'<"
            local stop = vim.fn.getpos "'>"
            local lines =
              vim.api.nvim_buf_get_lines(0, start[2] - 1, stop[2], false)
            local title = lines[1]
            local body = table.concat(lines, "\n", 2)
            -- Remove any leading or trailing whitespace
            title = vim.trim(title)
            body = vim.trim(body)

            create_issue { title = title, body = body }
          end

          vim.ui.input({ prompt = "Issue title: " }, function(title)
            if not title then
              return
            end

            vim.ui.input({ prompt = "Issue body: " }, function(body)
              create_issue { title = title, body = body }
            end)
          end)
        end,
        mode = { "n", "v" },
        desc = "Create issue",
      },
      {
        "<leader>op",
        "<CMD>Octo pr list<CR>",
        desc = "List pull requests",
      },
      {
        "<leader>oe",
        desc = "Create octo enum",
        function()
          local debug = require "octo.debug"
          local utils = require "octo.utils"

          local function create_callback(type)
            return function(data)
              local decoded = vim.json.decode(data)
              local enum_values = decoded.data.__type.enumValues

              if utils.is_blank(enum_values) then
                utils.error("No enum values found for type: " .. type)
                return
              end

              local typehint_parts = "---@alias octo." .. type
              local typehint_values = {}
              for _, enum in ipairs(enum_values) do
                table.insert(typehint_values, '"' .. enum.name .. '"')
              end

              local typehint = typehint_parts
                .. " "
                .. table.concat(typehint_values, "|")
              utils.copy_url(typehint)
            end
          end

          vim.ui.input({
            prompt = "Enter GraphQL type name: ",
          }, function(input)
            if input then
              debug.lookup(input, create_callback(input))
            end
          end)
        end,
      },
      {
        "<leader>ol",
        function()
          local debug = require "octo.debug"
          vim.ui.input({
            prompt = "Enter GraphQL type name: ",
          }, function(input)
            if input then
              debug.lookup(input)
            end
          end)
        end,
        desc = "Lookup GraphQL type",
      },
      { "<leader>oi", "<CMD>Octo issue list<CR>", desc = "List issues" },
      {
        "<leader>od",
        "<CMD>Octo discussion list<CR>",
        desc = "List discussions",
      },
    },
    depencencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      ---@type OctoConfig
      require("octo").setup {
        -- default_to_projects_v2 = true,
        suppress_missing_scope = {
          projects_v2 = true,
        },
        debug = {
          notify_missing_timeline_items = true,
        },
        use_local_fs = true,
        enable_builtin = true,
        default_to_projects_v2 = true,
        users = "assignable",
        timeout = 15000,
        notifications = {
          current_repo_only = true,
        },
        mappings = {
          discussion = {
            next_comment = { lhs = "]C", desc = "go to next comment" },
            prev_comment = { lhs = "[C", desc = "go to previous comment" },
          },
          pull_request = {
            next_comment = { lhs = "]C", desc = "go to next comment" },
            prev_comment = { lhs = "[C", desc = "go to previous comment" },
          },
          issue = {
            next_comment = { lhs = "]C", desc = "go to next comment" },
            prev_comment = { lhs = "[C", desc = "go to previous comment" },
          },
          notification = {
            read = { lhs = "<C-r>", desc = "mark notification as read" },
          },
          runs = {
            rerun = { lhs = "<C-R>", desc = "Rerun workflow" },
          },
        },
        use_timeline_icons = true,
        commands = {
          release = {
            -- list = function(repo)
            --   require("config.releases").create_picker {
            --     repo = repo,
            --   }
            -- end,
          },
          -- Octo commit list
          commit = {
            url = function()
              local gh = require "octo.gh"

              local query = [[
                query Last100Commits($owner: String!, $name: String!) {
                  repository(owner: $owner, name: $name) {
                    defaultBranchRef {
                      target {
                        ... on Commit {
                          history(first: 100) {
                            nodes {
                              oid
                              message
                              url
                            }
                          }
                        }
                      }
                    }
                  }
                }
                ]]

              local utils = require "octo.utils"
              local repo = utils.get_remote_name()
              local owner, name = utils.split_repo(repo)

              local result = gh.api.graphql {
                query = query,
                fields = {
                  owner = owner,
                  name = name,
                },
                jq = ".data.repository.defaultBranchRef.target.history.nodes",
                opts = {
                  cb = gh.create_callback {
                    success = function(data)
                      vim.ui.select(vim.json.decode(data), {
                        prompt = "Select a commit",
                        format_item = function(item)
                          return item.oid:sub(1, 7) .. " - " .. item.message
                        end,
                      }, function(selected)
                        if not selected then
                          return
                        end
                        vim.notify("Commit URL: " .. selected.url)
                      end)
                    end,
                  },
                },
              }
            end,
          },
          config = {
            notifications = function()
              local cfg = require("octo.config").values
              local utils = require "octo.utils"

              cfg.notifications.current_repo_only =
                not cfg.notifications.current_repo_only

              utils.info(
                "Current repo only set to "
                  .. tostring(cfg.notifications.current_repo_only)
              )
              ---TODO: This doesn't actually update
            end,
            picker = function()
              require("config.easy_picker").new(
                { "telescope", "fzf-lua", "snacks" },
                {
                  selected_callback = function(selected)
                    local cfg = require("octo.config").values
                    cfg.picker = selected.value
                    require("octo.picker").setup()
                    vim.notify("Picker set to " .. selected.value)
                  end,
                }
              )
            end,
          },
          issue = {
            transfer_to_repo = function(repo)
              local gh = require "octo.gh"
              local utils = require "octo.utils"

              local buffer = utils.get_current_buffer()

              if not buffer or not buffer:isIssue() then
                utils.error "Not in an issue buffer"
                return
              end

              local number = buffer:issue().number

              gh.issue.transfer {
                number,
                repo,
                opts = {
                  cb = gh.create_callback {},
                },
              }
            end,
            transfer = function(total)
              local limit = total or 100
              local gh = require "octo.gh"
              local utils = require "octo.utils"

              local buffer = utils.get_current_buffer()

              if not buffer or not buffer:isIssue() then
                utils.error "Not in an issue buffer"
                return
              end

              local viewer = vim.g.octo_viewer

              local number = buffer:issue().number

              gh.repo.list {
                limit = limit,
                json = "id,nameWithOwner",
                opts = {
                  cb = gh.create_callback {
                    success = function(output)
                      local repos = vim.json.decode(output)

                      vim.ui.select(repos, {
                        prompt = "Select a repository:",
                        format_item = function(item)
                          local name = item.nameWithOwner
                          name = string.gsub(name, viewer .. "/", "")
                          return name
                        end,
                      }, function(selected)
                        if not selected then
                          utils.error "No repository selected"
                          return
                        end

                        local message = function()
                          utils.info(
                            "Transferring issue "
                              .. number
                              .. " to "
                              .. selected.nameWithOwner
                          )
                        end

                        gh.issue.transfer {
                          number,
                          selected.nameWithOwner,
                          opts = {
                            cb = gh.create_callback { success = message },
                          },
                        }
                      end)
                    end,
                  },
                },
              }
            end,
          },
          auth = {
            status = function()
              local gh = require "octo.gh"
              local utils = require "octo.utils"

              local output =
                gh.auth.status { active = true, opts = { mode = "sync" } }
              utils.info(output)
            end,
            switch = function(user)
              local gh = require "octo.gh"

              local opts = {
                opts = { mode = "sync" },
              }
              if user then
                opts.user = user
              end
              local _, output = gh.auth.switch(opts)
              vim.notify("Output: " .. output, vim.log.levels.INFO)

              -- Change the viewer global
              local split = vim.split(output, " ")
              user = split[#split]
              vim.g.octo_viewer = user
            end,
          },
        },
        discussions = {
          order_by = {
            field = "UPDATED_AT",
            direction = "DESC",
          },
        },
        pull_requests = {
          order_by = {
            field = "UPDATED_AT",
            direction = "DESC",
          },
        },
        issues = {
          body_callback = function(body)
            return body .. "\n\n*Created via octo.nvim*"
          end,
          order_by = {
            field = "UPDATED_AT",
            direction = "DESC",
          },
        },
        ---Choose picker
        picker = "telescope",
        -- picker = "snacks",
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

      -- Add the key mapping only for octo filetype
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "octo",
        callback = function()
          vim.keymap.set(
            "i",
            "@",
            "@<C-x><C-o>",
            { buffer = true, silent = true }
          )
          vim.keymap.set(
            "i",
            "#",
            "#<C-x><C-o>",
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
