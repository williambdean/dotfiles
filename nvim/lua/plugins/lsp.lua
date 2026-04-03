local vim = vim

return {
  -- 1. Mason for Managing Binaries
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {
      ensure_installed = {
        "ruff",
        "pyright",
        "tinymist",
        "typstyle",
        "lua-language-server",
        "yaml-language-server",
        "typescript-language-server",
        "copilot-language-server",
        "vscode-html-language-server",
        "shfmt",
        "codespell",
        "html-lsp",
        "prettier",
      },
    },
  },

  -- 2. mason-lspconfig: auto-enables Mason-installed servers via vim.lsp.enable()
  --    Repo moved from williamboman/ to mason-org/ in v2.0
  --    Depends on nvim-lspconfig so its lsp/ dir is on runtimepath first.
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      -- automatic_enable = true is the default in v2.x: calls vim.lsp.enable()
      -- for every Mason-installed server that has a vim.lsp.config definition.
    },
  },

  -- 3. nvim-lspconfig: provides server defaults (cmd, filetypes, root detection)
  --    Must load eagerly (no event lazy-loading) so its lsp/*.lua files are on
  --    the runtimepath when mason-lspconfig calls vim.lsp.enable() at startup.
  --    Do NOT use require('lspconfig') -- deprecated in favour of vim.lsp.config.
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Apply base options to ALL servers via wildcard.
      -- Per-server vim.lsp.config() calls below are merged on top.
      vim.lsp.config("*", {
        capabilities = capabilities,
        flags = {
          -- Disable incremental sync to avoid sync.lua assertion crashes.
          allow_incremental_sync = false,
          debounce_text_changes = 150,
        },
      })

      -- Per-server overrides (only where custom settings are needed)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "off", -- Let Ruff handle diagnostics
            },
          },
        },
      })

      -- LSP Keymaps
      -- nvim 0.12 built-in defaults cover: K (hover), grn (rename),
      -- gra (code_action), grr (references), gri (implementation),
      -- grt (type_definition), grx (codelens). Only map what differs.
      local group = vim.api.nvim_create_augroup("UserLspConfig", {})
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(ev)
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "<leader>=", function()
            vim.lsp.buf.format { async = false }
          end, opts)
        end,
      })

      -- Auto-format on save
      local lsp_format_enabled = true
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        callback = function(ev)
          if vim.bo.filetype == "markdown" or not lsp_format_enabled then
            return
          end
          -- pcall prevents save from hanging on LSP errors
          pcall(function()
            vim.lsp.buf.format { bufnr = ev.buf, async = false }
          end)
        end,
      })

      -- Diagnostics UI
      vim.diagnostic.config {
        virtual_text = { prefix = "●", spacing = 5 },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      }

      -- Custom Commands
      vim.api.nvim_create_user_command("LspEnableFormat", function()
        lsp_format_enabled = true
      end, {})
      vim.api.nvim_create_user_command("LspDisableFormat", function()
        lsp_format_enabled = false
      end, {})
    end,
  },
}
