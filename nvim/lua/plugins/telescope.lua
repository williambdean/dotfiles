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
  { "nvim-telescope/telescope-symbols.nvim" },
  { "xiyaowong/telescope-emoji.nvim" },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    extensions = {
      emoji = {
        action = function(emoji)
          vim.fn.setreg("*", emoji.value)
        end,
      },
    },
    keys = {
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

          -- params = {
          --     cwd = cwd,
          --     search_dirs = { cwd },
          -- }
          params = {}

          -- TODO: Bug where in a git repo but in a non-git directory

          local search
          if is_git_repo() then
            search = require("telescope.builtin").git_files
            -- params.use_git_root = false
          else
            search = require("telescope.builtin").find_files
          end

          search(params)
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
          local cwd = require("oil").get_current_dir()
          -- params = {
          --     cwd = cwd,
          --     search_dirs = { cwd },
          -- }
          local params = {}
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
    },
  },
}
