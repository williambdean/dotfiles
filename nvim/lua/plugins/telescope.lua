local is_git_repo = function()
  local git_dir = vim.fn.system("git rev-parse --is-inside-work-tree")
  return vim.v.shell_error == 0
end

local find_site_packages = function()
  return vim.trim(
    vim.fn.system("python -c 'import site; print(site.getsitepackages()[0])'")
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
          require("telescope.builtin").find_files({
            cwd = find_site_packages(),
            glob_pattern = "*.py",
          })
        end,
      },
      {
        "<leader>pg",
        function()
          require("telescope.builtin").live_grep({
            cwd = find_site_packages(),
            glob_pattern = "*.py",
          })
        end,
      },
      {
        "<leader>fp",
        function()
          require("telescope.builtin").oldfiles({ only_cwd = true })
        end,
      },
      {
        "<leader>ff",
        function()
          local cwd
          if vim.bo.filetype == "oil" then
            cwd = require("oil").get_current_dir()
          else
            cwd = vim.fn.expand("%:p:h")
          end

          print("The current working directory")
          vim.print(cwd)

          params = {
            cwd = cwd,
            search_dirs = { cwd },
          }
          -- params = {}

          -- TODO: Bug where in a git repo but in a non-git directory
          --
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
      },
      {
        "<leader>fc",
        function()
          require("telescope.builtin").resume()
        end,
      },
      {
        "<leader>fd",
        function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
      },
      {
        "<leader>fg",
        function()
          local cwd
          if vim.bo.filetype == "oil" then
            cwd = require("oil").get_current_dir()
          else
            cwd = vim.fn.expand("%:p:h")
          end
          local params = {
            cwd = cwd,
            search_dirs = { cwd },
          }
          require("telescope.builtin").live_grep(params)
        end,
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
      },
      {
        "<leader>*",
        function()
          require("telescope.builtin").grep_string({
            search = vim.fn.expand("<cWORD>"),
          })
        end,
      },
      {
        "<leader>,",
        function()
          require("telescope.builtin").buffers({
            sort_mru = true,
          })
        end,
      },
    },
  },
}
