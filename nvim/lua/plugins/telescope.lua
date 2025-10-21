local is_git_repo = function()
  local git_dir = vim.fn.system "git rev-parse --is-inside-work-tree"
  return vim.v.shell_error == 0
end

local find_site_packages = function()
  return vim.trim(
    vim.fn.system "python -c 'import site; print(site.getsitepackages()[0])'"
  )
end

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-symbols.nvim",
      "xiyaowong/telescope-emoji.nvim",
    },
    extensions = {
      emoji = {
        action = function(emoji)
          vim.fn.setreg("*", emoji.value)
        end,
      },
      symbols = {
        action = function(symbol)
          vim.fn.setreg("*", symbol.value)
        end,
      },
    },
    cmd = { "Telescope" },
    keys = {
      {
        "<C-s>",
        mode = "i",
        action = "<C-o>:Telescope spell_suggest<CR>",
        desc = "Spell suggestions",
      },
      {
        "<C-s>",
        mode = "n",
        action = ":Telescope spell_suggest<CR>",
        desc = "Spell suggestions",
      },
      {
        "<leader>pf",
        function()
          require("telescope.builtin").find_files {
            cwd = find_site_packages(),
            glob_pattern = "*.py",
          }
        end,
        desc = "Find Python environment files",
      },
      {
        "<leader>pg",
        function()
          require("telescope.builtin").live_grep {
            cwd = find_site_packages(),
            glob_pattern = "*.py",
          }
        end,
        desc = "Grep Python environment files",
      },
      {
        "<leader>fp",
        function()
          require("telescope.builtin").oldfiles { only_cwd = true }
        end,
        desc = "Find previous files",
      },
      {
        "<leader>zf",
        function()
          local builtin = require "telescope.builtin"
          local zoxide = require "config.zoxide"
          zoxide.picker(function(cwd)
            builtin.find_files {
              cwd = cwd,
              search_dirs = { cwd },
              attach_mappings = function(_, map)
                map("i", "<CR>", function(prompt_bufnr)
                  require("telescope.actions").select_default(prompt_bufnr)
                  vim.cmd.lcd(cwd)
                end)
                return true
              end,
            }
          end)
        end,
        desc = "Zoxide then file picker",
      },
      {
        "<leader>fd",
        function()
          local default_branch = vim.fn
            .systemlist({
              "git",
              "rev-parse",
              "--abbrev-ref",
              "origin/HEAD",
            })[1]
            :gsub("origin/", "")

          local files = vim.fn.systemlist {
            "git",
            "diff",
            "--name-only",
            default_branch,
          }

          if vim.v.shell_error ~= 0 then
            vim.notify(
              "Not a git repository or no differences found",
              vim.log.levels.WARN
            )
            return
          end

          if #files == 0 then
            vim.notify(
              "No differences found with " .. default_branch,
              vim.log.levels.INFO
            )
            return
          end

          require("telescope.pickers")
            .new({}, {
              prompt_title = "Files different from " .. default_branch,
              finder = require("telescope.finders").new_table {
                results = files,
              },
              sorter = require("telescope.config").values.generic_sorter {},
              previewer = require("telescope.previewers").vim_buffer_cat.new {},
            })
            :find()
        end,
        desc = "Find differences with git default branch",
      },
      {
        "<leader>ff",
        function()
          local cwd
          if vim.bo.filetype == "oil" then
            cwd = require("oil").get_current_dir()
          else
            cwd = vim.loop.cwd()
          end

          local params = {
            cwd = cwd,
            search_dirs = { cwd },
            follow = true,
            hidden = true,
            no_ignore = true,
            no_ignore_parent = false,
          }

          -- require("telescope.builtin").find_files(params)

          local search
          if is_git_repo() then
            search = require("telescope.builtin").git_files
            -- params.use_git_root = false
          else
            search = require("telescope.builtin").find_files
          end

          search(params)
        end,
        desc = "Find files",
      },
      {
        "<leader>fc",
        function()
          require("telescope.builtin").resume()
        end,
        desc = "Continue last search",
      },
      -- {
      --   "<leader>fd",
      --   function()
      --     local dotfiles_dir = vim.fn.expand "$HOME/GitHub/dotfiles"
      --     require("telescope.builtin").find_files {
      --       cwd = dotfiles_dir,
      --       search_dirs = { dotfiles_dir },
      --       prompt_title = "Dotfiles",
      --     }
      --   end,
      --   desc = "Find dotfiles",
      -- },
      {
        "<leader>fg",
        function()
          vim.notify("Use <leader>/ instead", vim.log.levels.WARN)
        end,
        desc = "Old mapping",
      },
      {
        "<leader>z/",
        function()
          local builtin = require "telescope.builtin"
          local zoxide = require "config.zoxide"
          zoxide.picker(function(cwd)
            builtin.live_grep {
              cwd = cwd,
              search_dirs = { cwd },
              attach_mappings = function(_, map)
                map("i", "<CR>", function(prompt_bufnr)
                  require("telescope.actions").select_default(prompt_bufnr)
                  vim.cmd.lcd(cwd)
                end)
                return true
              end,
            }
          end)
        end,
        desc = "Zoxide then grep",
      },

      {
        "<leader>/",
        function()
          local cwd
          if vim.bo.filetype == "oil" then
            cwd = require("oil").get_current_dir()
          else
            cwd = vim.loop.cwd()
          end
          local params = {
            cwd = cwd,
            search_dirs = { cwd },
          }
          if is_git_repo() then
            params.hidden = true
          end
          require("telescope.builtin").live_grep(params)
        end,
        desc = "Find grep",
      },
      {
        "<leader>nf",
        function()
          local opts = {}
          local obsidian = require "config.obsidian"
          if not obsidian.directory_exists then
            vim.notify(
              "Obsidian vault not found. Please set the directory in your config.",
              vim.log.levels.WARN
            )
            return
          end
          opts.cwd = obsidian.directory
          opts.attach_mappings = function(prompt_bufnr, map)
            map("i", "<CR>", function()
              local actions = require "telescope.actions"
              local action_state = require "telescope.actions.state"
              local current_line = action_state.get_current_line()
              local selection = action_state.get_selected_entry()

              if selection == nil then
                local file_path = obsidian.directory .. "/" .. current_line
                local dir_path = vim.fn.fnamemodify(file_path, ":h")

                vim.fn.mkdir(dir_path, "p")
                vim.cmd.edit { bang = true, args = { file_path } }
              else
                actions.select_default(prompt_bufnr)
              end
              return true
            end)
            return true
          end
          require("telescope.builtin").find_files(opts)
        end,
        desc = "Find Obsidian notes",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Find help tags",
      },
      {
        "<leader>*",
        function()
          require("telescope.builtin").grep_string {
            search = vim.fn.expand "<cWORD>",
          }
        end,
        desc = "Search word under cursor",
      },
      {
        "<leader>,",
        function()
          require("telescope.builtin").buffers {
            sort_mru = true,
          }
        end,
        desc = "Find buffers",
      },
    },
  },
}
