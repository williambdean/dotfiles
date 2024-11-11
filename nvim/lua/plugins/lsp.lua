local function get_stylua_config()
  return {
    runtime = {
      version = "LuaJIT",
      path = vim.split(package.path, ";"),
    },
    diagnostics = {
      globals = { "vim" },
    },
    workspace = {
      library = vim.api.nvim_get_runtime_file("", true),
      checkThirdParty = false,
    },
    telemetry = {
      enable = false,
    },
    format = {
      enable = false,
    },
  }
end

local function get_stylua_config_old()
  local util = require("lspconfig.util")

  local stylua_config_path = util.path.join(vim.fn.getcwd(), ".stylua.toml")
  if util.path.exists(stylua_config_path) then
    print("Using the local .stylua.toml")
    return {
      format = {
        enable = true,
        config = stylua_config_path,
      },
    }
  end

  local config = {
    format = {
      enable = true,
      defaultConfig = {
        indentType = "Spaces",
        indentWidth = 4,
        columnWidth = 80,
        lineEndings = "Unix",
      },
    },
  }

  return config
end

return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {
      ensure_installed = {
        "ruff",
        "pyright",
        "lua-language-server",
        "yaml-language-server",
        "shfmt",
        "codespell",
      },
    },
    config = function()
      require("mason").setup({
        pip = {
          upgrade_pip = true,
        },
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    depends = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup()

      local lspconfig = require("lspconfig")
      lspconfig.graphql.setup({})
      lspconfig.ruff.setup({
        on_new_config = function(config, root_dir)
          -- Look for .venv directory in the project root
          local venv_path = vim.fn.finddir(".venv", root_dir .. ";")
          if venv_path ~= "" then
            -- Use the site-packages from .venv directory
            config.cmd_env = {
              PYTHONPATH = venv_path .. "/lib/python3.*/site-packages",
            }
          end
        end,
      })
      lspconfig.pyright.setup({
        on_init = function(client)
          client.config.settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
              venvPath = vim.fn.getcwd(),
              pythonPath = nil, -- Let pyright detect the interpreter
            },
          }
        end,
        on_new_config = function(config, root_dir)
          -- Look for .venv or venv directory in the project root
          local venv = vim.fn.finddir(".venv", root_dir .. ";")
          if venv == "" then
            venv = vim.fn.finddir("venv", root_dir .. ";")
          end

          if venv ~= "" then
            local python_path = vim.fn.glob(venv .. "/bin/python")
            config.settings = {
              python = {
                pythonPath = python_path,
                venvPath = venv,
              },
            }
          end
        end,
      })
      lspconfig.harper_ls.setup({})
      lspconfig.lua_ls.setup({
        settings = {
          Lua = get_stylua_config(),
        },
        ft = ".lua",
      })

      local group = vim.api.nvim_create_augroup("UserLspConfig", {})
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(ev)
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>=", vim.lsp.buf.format, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          -- vim.keymap.set("n", "<leader>e", vim.lsp.diagnostic.show_line_diagnostics, opts)
        end,
      })
      -- Define a global variable to control formatting
      vim.g.lsp_format_enabled = true

      vim.diagnostic.config({
        virtual_text = {
          prefix = "●", -- Could be '●', '▎', 'x'
          source = "if_many", -- Or "always"
          spacing = 5,
          severity_limit = "Warning",
          right_align = false, -- Align to the right
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Modify the autocmd to check the global variable before formatting
      vim.api.nvim_create_autocmd("BufWritePre", {
        -- buffer = buffer,
        group = group,
        callback = function()
          if vim.g.lsp_format_enabled then
            vim.lsp.buf.format({ async = false })
          end
        end,
      })

      -- Format commands
      vim.api.nvim_create_user_command("LspEnableFormat", function()
        vim.g.lsp_format_enabled = true
      end, {})

      vim.api.nvim_create_user_command("LspDisableFormat", function()
        vim.g.lsp_format_enabled = false
      end, {})

      vim.api.nvim_create_user_command("LspFormat", function()
        vim.lsp.buf.format({ async = false })
      end, {})

      -- -- For shell scripts
      -- vim.api.nvim_create_autocmd("BufWritePre", {
      --     pattern = "*.sh",
      --     group = group,
      --     callback = function()
      --         vim.cmd("!shfmt -w %")
      --     end,
      -- })

      -- Add the diagnostics to the right of the screen
      -- instead of the left side which pushes it out
      vim.diagnostic.config({
        virtual_text = true,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
  },
}
