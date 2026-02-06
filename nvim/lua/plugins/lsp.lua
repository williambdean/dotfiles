local vim = vim

return {
  -- 1. Mason for Managing Binaries
  {
    "williamboman/mason.nvim",
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
    config = function(_, opts)
      require("mason").setup(opts)
    end,
  },

  -- 2. LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local lspconfig = require "lspconfig"
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- THE CORE FIX: Disable incremental sync to stop sync.lua assertion crashes.
      -- This forces Full Sync, bypassing the buggy line-length calculation in 0.11.5.
      local base_opts = {
        capabilities = capabilities,
        flags = {
          allow_incremental_sync = false,
          debounce_text_changes = 150,
        },
      }

      -- Setup LUA
      lspconfig.lua_ls.setup(vim.tbl_deep_extend("force", base_opts, {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      }))

      -- Setup PYTHON (Pyright)
      lspconfig.pyright.setup(vim.tbl_deep_extend("force", base_opts, {
        settings = {
          python = {
            analysis = {
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "off", -- Let Ruff handle diagnostics
            },
          },
        },
      }))

      -- List of all other servers to initialize with the safe flags
      local servers = {
        "ruff",
        "ts_ls",
        "rust_analyzer",
        "html",
        "gh_actions_ls",
        "tinymist",
        "typstyle",
        "graphql",
        "harper_ls",
        "air",
      }

      for _, server in ipairs(servers) do
        lspconfig[server].setup(base_opts)
      end

      -- LSP Keymaps & Shared Behavior
      local group = vim.api.nvim_create_augroup("UserLspConfig", {})
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(ev)
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>=", function()
            vim.lsp.buf.format { async = false }
          end, opts)
        end,
      })

      -- Formatting Logic
      local lsp_format_enabled = true
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        callback = function(ev)
          if vim.bo.filetype == "markdown" or not lsp_format_enabled then
            return
          end
          -- Use pcall to prevent the save process from hanging if an LSP error occurs
          pcall(function()
            vim.lsp.buf.format { bufnr = ev.buf, async = false }
          end)
        end,
      })

      -- Diagnostics UI Configuration
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
