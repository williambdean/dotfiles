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
        "<leader>ff",
        function()
          local cwd
          if vim.bo.filetype == "oil" then
            cwd = require("oil").get_current_dir()
          else
            cwd = vim.loop.cwd()
          end

          params = {
            cwd = cwd,
            search_dirs = { cwd },
          }

          require("telescope.builtin").find_files(params)

          -- local search
          -- if is_git_repo() then
          --     search = require("telescope.builtin").git_files
          --     -- params.use_git_root = false
          -- else
          --     search = require("telescope.builtin").find_files
          -- end
          --
          -- search(params)
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
      {
        "<leader>fd",
        function()
          local dotfiles_dir = vim.fn.expand "$HOME/GitHub/dotfiles"
          require("telescope.builtin").find_files {
            cwd = dotfiles_dir,
            search_dirs = { dotfiles_dir },
            prompt_title = "Dotfiles",
          }
        end,
        desc = "Find dotfiles",
      },
      {
        "<leader>fg",
        function()
          vim.notify("Use <leader>/ instead", vim.log.levels.WARN)
        end,
        desc = "Old mapping",
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
