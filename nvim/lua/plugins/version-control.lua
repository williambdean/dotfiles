--- Creates an issue on GitHub using GitHub CLI
---
-- @param opts A table containing the title and body of the issue.
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

vim.keymap.set("v", "<leader>gho", function()
  require("gitlinker").link {
    action = require("gitlinker.actions").open_in_browser,
    message = false,
    remote = has_upstream() and "upstream" or "origin",
  }
end, {})

vim.api.nvim_create_user_command("CloseIssue", function(opts)
  require("config.close-issue").close_issue()
end, {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "octo",
  callback = function()
    vim.keymap.set("n", "<leader>B", function()
      local utils = require "octo.utils"
      local buffer = utils.get_current_buffer()
      if not buffer then
        utils.error "Not in an octo buffer"
        return
      end

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

  local author = buffer.node.author.login
  vim.fn.setreg("+", "@" .. author)
  utils.info("Copied author to clipboard: " .. author)
end

vim.keymap.set("n", "<leader>A", current_author, { silent = true })

local function create_octo_search(opts)
  local cmd = ":Octo search "
  local utils = require "octo.utils"

  if opts.include_repo then
    local repo = utils.get_remote_name()
    if repo ~= nil then
      cmd = cmd .. "repo:" .. repo .. " "
    else
      utils.error "No remote found"
    end
  end

  if opts.query then
    cmd = cmd .. opts.query
  end

  return cmd
end

local function github_search(opts)
  local cmd = create_octo_search(opts)
  vim.fn.feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n")
end

vim.keymap.set("n", "<leader>os", function()
  github_search { include_repo = true }
end, { silent = true, desc = "GitHub search for the current repository" })
vim.keymap.set("n", "<leader>oS", function()
  github_search { include_repo = false }
end, { silent = true, desc = "GitHub search" })

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

  opts.repo = opts.repo or utils.get_remote_name()
  local owner, name = utils.split_repo(opts.repo)

  local fields = {
    owner = owner,
    name = name,
    number = opts.number,
  }

  local result = gh.api.graphql {
    query = query,
    fields = fields,
    opts = {
      mode = "sync",
    },
  }
  result = vim.json.decode(result)

  local repository = result.data.repository

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

  local typename = get_typename {
    number = number,
  }
  local get_uri = {
    Issue = utils.get_issue_uri,
    PullRequest = utils.get_pull_request_uri,
    Discussion = utils.get_discussion_uri,
  }

  get_uri = get_uri[typename]
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
    "lewis6991/gitsigns.nvim",
    opts = {},
  },
  {
    dir = "~/GitHub/neovim-plugins/octo.nvim",
    cmd = "Octo",
    keys = {
      { "<leader>oo", "<CMD>Octo<CR>", desc = "Open Octo" },
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
      require("octo").setup {
        -- default_to_projects_v2 = true,
        use_local_fs = false,
        enable_builtin = true,
        default_to_projects_v2 = true,
        users = "assignable",
        timeout = 15000,
        notifications = {
          current_repo_only = true,
        },
        mappings = {
          notification = {
            read = { lhs = "<C-r>", desc = "mark notification as read" },
          },
        },
        use_timeline_icons = true,
        commands = {
          release = {
            list = function(repo)
              require("config.releases").create_picker {
                repo = repo,
              }
            end,
          },
          pr = {
            auto = function()
              local gh = require "octo.gh"
              local picker = require "octo.picker"
              local utils = require "octo.utils"

              local buffer = utils.get_current_buffer()

              local auto_merge = function(number)
                local cb = function()
                  utils.info "This PR will be auto-merged"
                end
                local opts = { cb = cb }
                gh.pr.merge { number, auto = true, squash = true, opts = opts }
              end

              if not buffer or not buffer:isPullRequest() then
                picker.prs {
                  cb = function(selected)
                    auto_merge(selected.obj.number)
                  end,
                }
                return
              else
                auto_merge(buffer.node.number)
              end
            end,
            celebrate = function()
              local utils = require "octo.utils"
              local buffer = utils.get_current_buffer()
              if not buffer or not buffer:isPullRequest() then
                utils.error "Wrong place to celebrate"
                return
              end

              local state = buffer.node.state

              if state ~= "MERGED" then
                utils.error "PR is not merged yet. Isn't it too early to celebrate?"
                return
              end

              if vim.g.octo_viewer ~= buffer.node.author.login then
                utils.info(
                  "You are not the author of this PR. Go celebrate with "
                    .. buffer.node.author.login
                )
                return
              end

              utils.info(
                "Congratulations! 🎉 Well done on " .. buffer.node.title
              )
            end,
            update = function()
              local gh = require "octo.gh"
              local utils = require "octo.utils"
              local buffer = utils.get_current_buffer()
              if not buffer or not buffer:isPullRequest() then
                utils.error "Not in a pull request buffer"
                return
              end

              gh.pr["update-branch"] {
                buffer.node.number,
                opts = { cb = gh.create_callback {} },
              }
            end,
          },
          label = {
            list = function()
              local picker = require "octo.picker"

              picker.labels {
                cb = function(labels)
                  local combined_labels = ""
                  for _, l in ipairs(labels) do
                    combined_labels = combined_labels .. "," .. l.name
                  end
                  combined_labels = string.sub(combined_labels, 2) -- Remove leading comma

                  github_search {
                    query = "label:" .. combined_labels,
                    include_repo = true,
                  }
                end,
              }
            end,
          },
          my_notification = {
            list = function()
              local utils = require "octo.utils"

              local opts = {}

              if vim.fn.confirm("Current Repo Only?", "&Yes\n&No", 1) == 1 then
                opts.repo = utils.get_remote_name()
              end

              require("octo.picker").notifications(opts)
            end,
            all = function()
              local utils = require "octo.utils"

              local opts = { all = true }

              if vim.fn.confirm("Current Repo Only?", "&Yes\n&No", 1) == 1 then
                opts.repo = utils.get_remote_name()
              end

              require("octo.picker").notifications(opts)
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

              local number = buffer.node.number

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

              local number = buffer.node.number

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
          order_by = {
            field = "UPDATED_AT",
            direction = "DESC",
          },
        },
        picker = "telescope",
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
          vim.keymap.set("n", "la", function()
            vim.notify "Use <localleader>la instead"
          end, { silent = true, buffer = true })
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
