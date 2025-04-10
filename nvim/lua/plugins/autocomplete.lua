local function quick_chat(with_buffer)
  local chat = require "CopilotChat"
  local select = require "CopilotChat.select"

  local prompt = "Quick Chat: "

  if with_buffer then
    prompt = "Quick Chat (Buffer): "
  end

  local handle_input = function(input)
    if input == "" then
      return
    end

    if with_buffer then
      chat.ask(input, {
        selection = select.buffer,
      })
    else
      chat.ask(input)
    end
  end

  vim.ui.input({ prompt = prompt }, handle_input)
end

vim.keymap.set("i", "@", "@<C-x><C-o>", { silent = true, buffer = true })
vim.keymap.set("i", "#", "#<C-x><C-o>", { silent = true, buffer = true })

return {
  {
    "saghen/blink.cmp",
    -- optional: provides snippets for the snippet source
    dependencies = { "rafamadriz/friendly-snippets" },

    -- use a release tag to download pre-built binaries
    version = "*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = { preset = "default" },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },

    --- Custom

    cmdline = { enabled = false },
  },
  -- {
  --   'echasnovski/mini.completion',
  --   version = '*',
  --   opts = {},
  -- },

  -- {
  --   "hrsh7th/nvim-cmp",
  --   version = false, -- last release is way too old
  --   event = "InsertEnter",
  --   dependencies = {
  --     "hrsh7th/cmp-nvim-lsp",
  --     "hrsh7th/cmp-buffer",
  --     "hrsh7th/cmp-path",
  --   },
  --   -- Not all LSP servers add brackets when completing a function.
  --   -- To better deal with this, LazyVim adds a custom option to cmp,
  --   -- that you can configure. For example:
  --   --
  --   -- ```lua
  --   -- opts = {
  --   --   auto_brackets = { "python" }
  --   -- }
  --   -- ```
  --   opts = function()
  --     vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
  --     local cmp = require("cmp")
  --     local defaults = require("cmp.config.default")()
  --     local auto_select = true
  --     return {
  --       auto_brackets = {}, -- configure any filetype to auto add brackets
  --       completion = {
  --         completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
  --       },
  --       preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
  --       mapping = cmp.mapping.preset.insert({
  --         ["<C-b>"] = cmp.mapping.scroll_docs(-4),
  --         ["<C-f>"] = cmp.mapping.scroll_docs(4),
  --         ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
  --         ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
  --         ["<C-Space>"] = cmp.mapping.complete(),
  --         -- ["<CR>"] = LazyVim.cmp.confirm({ select = auto_select }),
  --         -- ["<C-y>"] = LazyVim.cmp.confirm({ select = true }),
  --         -- ["<S-CR>"] = LazyVim.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --         ["<C-CR>"] = function(fallback)
  --           cmp.abort()
  --           fallback()
  --         end,
  --         -- ["<tab>"] = function(fallback)
  --         --   return LazyVim.cmp.map({ "snippet_forward", "ai_accept" }, fallback)()
  --         -- end,
  --       }),
  --       sources = cmp.config.sources({
  --         { name = "lazydev" },
  --         { name = "nvim_lsp" },
  --         { name = "path" },
  --       }, {
  --         { name = "buffer" },
  --       }),
  --       formatting = {
  --         format = function(entry, item)
  --           local icons = LazyVim.config.icons.kinds
  --           if icons[item.kind] then
  --             item.kind = icons[item.kind] .. item.kind
  --           end
  --
  --           local widths = {
  --             abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr or 40,
  --             menu = vim.g.cmp_widths and vim.g.cmp_widths.menu or 30,
  --           }
  --
  --           for key, width in pairs(widths) do
  --             if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
  --               item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
  --             end
  --           end
  --
  --           return item
  --         end,
  --       },
  --       experimental = {
  --         -- only show ghost text when we show ai completions
  --         ghost_text = vim.g.ai_cmp and {
  --           hl_group = "CmpGhostText",
  --         } or false,
  --       },
  --       sorting = defaults.sorting,
  --     }
  --   end,
  --   main = "lazyvim.util.cmp",
  -- },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   lazy = true,
  --   event = {
  --     "InsertEnter",
  --     "CmdlineEnter",
  --   },
  --   config = function()
  --     local cmp = require "cmp"
  --     cmp.setup {
  --       snippet = {
  --         expand = function(args)
  --           vim.fn["vsnip#anonymous"](args.body)
  --         end,
  --       },
  --       completion = {
  --         keyword_length = 1, -- Set the minimum keyword length to trigger completion
  --       },
  --       mapping = {
  --         ["<C-d>"] = cmp.mapping.scroll_docs(-4),
  --         ["<C-f>"] = cmp.mapping.scroll_docs(4),
  --         ["<C-Space>"] = cmp.mapping.complete(),
  --         ["<C-e>"] = cmp.mapping.close(),
  --         ["<CR>"] = cmp.mapping.confirm {
  --           behavior = cmp.ConfirmBehavior.Insert,
  --           select = true,
  --         },
  --       },
  --       sources = {
  --         { name = "nvim_lsp" },
  --         { name = "vsnip" },
  --         { name = "buffer" },
  --         { name = "path" },
  --         { name = "copilot" },
  --         { name = "graphql" },
  --       },
  --     }
  --     cmp.setup.filetype("copilot-chat", {
  --       sources = cmp.config.sources {
  --         { name = "copilot" },
  --         { name = "buffer" },
  --         { name = "path" },
  --       },
  --     })
  --   end,
  -- },
  {
    "zbirenbaum/copilot.lua",
    cmd = { "Copilot" },
    event = "InsertEnter",
    opts = {},
  },
  {
    "github/copilot.vim",
    config = function()
      -- Enable Copilot for specific filetypes including custom ones
      vim.g.copilot_filetypes = {
        ["*"] = true, -- Enable for all filetypes
        ["copilot-chat"] = true, -- Explicitly enable for copilot-chat
        ["markdown"] = true, -- Enable for markdown
        ["yaml"] = true, -- Enable for yaml
        ["gitcommit"] = true, -- Enable for git commits
      }

      -- -- Copilot general settings
      -- vim.g.copilot_no_tab_map = true -- Disable tab mapping
      -- vim.g.copilot_assume_mapped = true
      -- vim.g.copilot_tab_fallback = ""
      vim.g.copilot_no_tab_map = false -- Enable tab mapping
      vim.g.copilot_assume_mapped = false -- Disable assume mapped
      -- vim.g.copilot_tab_fallback = "" -- Empty fallback

      vim.keymap.set("i", "<Tab>", function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        else
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
            "n",
            false
          )
        end
      end, { silent = true })

      -- Create mapping for manual trigger
      vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', {
        expr = true,
        replace_keycodes = false,
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      -- { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
    init = function()
      -- Custom buffer for CopilotChat
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "copilot-*",
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
        end,
      })
    end,
    opts = {
      debug = false,
      chat_autocomplete = true,
      auto_follow_cursor = true,
      model = "claude-3.7-sonnet",
      show_help = false,
      context = "buffers",
      language = "English",
      prompts = {
        Explain = "Explain how it works in the English language.",
        Review = "Review the following code and provide concise suggestions.",
        Tests = "Write tests for the following code.",
        Anything = "Respond to the following question.",
      },
      build = function()
        vim.notify "Please update the remote plugins by running :UpdateRemotePlugins, the"
      end,
      event = "VeryLazy",
    },
    keys = {
      {
        "<leader>t",
        function()
          require("CopilotChat").toggle()
        end,
        desc = "CopilotChat - Toggle",
      },
      {
        "<leader>ccq",
        function()
          quick_chat(false)
        end,
        desc = "CopilotChat - Quick Chat",
      },
      {
        "<leader>ccb",
        function()
          quick_chat(true)
        end,
        desc = "CopilotChat - Quick Chat (Buffer)",
      },
      {
        "<leader>cch",
        function()
          local actions = require "CopilotChat.actions"
          require("CopilotChat.integrations.telescope").pick(
            actions.help_actions()
          )
        end,
        desc = "CopilotChat - Help actions",
      },
      {
        "<leader>ccp",
        function()
          local actions = require "CopilotChat.actions"
          local select = require "CopilotChat.select"
          require("CopilotChat.integrations.telescope").pick(
            actions.prompt_actions { selection = select.buffer }
          )
        end,
        desc = "CopilotChat - Prompt actions",
      },
      {
        "<leader>ccv",
        function()
          local chat = require "CopilotChat"
          local select = require "CopilotChat.select"

          local question = vim.fn.input "Quick Chat (Visual): "
          chat.ask(question, { selection = select.visual })
        end,
        mode = "v",
        desc = "CopilotChat - Visual",
      },
      {
        "<leader>cci",
        function()
          local chat = require "CopilotChat"
          local select = require "CopilotChat.select"

          local question = vim.fn.input "Quick Chat (Visual): "
          chat.ask(question, {
            selection = select.visual,
            window = {
              layout = "float",
              relative = "cursor",
              width = 1,
              height = 0.4,
              row = 1,
            },
          })
        end,
        mode = "x",
        desc = "CopilotChat - Inline",
      },
    },
    cmd = {
      "CopilotChatToggle",
      "CopilotChat",
    },
  },
}
