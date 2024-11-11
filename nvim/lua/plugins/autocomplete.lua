local function quick_chat(with_buffer)
  local chat = require("CopilotChat")
  local select = require("CopilotChat.select")

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

return {
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },

        mapping = {
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
          }),
        },

        sources = {
          { name = "nvim_lsp" },
          { name = "vsnip" },
          { name = "buffer" },
          { name = "path" },
          { name = "copilot" },
        },
      })
      cmp.setup.filetype("copilot-chat", {
        sources = cmp.config.sources({
          { name = "copilot" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
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
    branch = "canary",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
    config = function()
      require("CopilotChat.integrations.cmp").setup()

      -- Custom buffer for CopilotChat
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "copilot-*",
        callback = function()
          vim.opt_local.relativenumber = true
          vim.opt_local.number = true

          -- Get current filetype and set it to markdown if the current filetype is copilot-chat
          -- local ft = vim.bo.filetype
          -- if ft == "copilot-chat" then
          --     vim.bo.filetype = "markdown"
          -- end
        end,
      })
      require("CopilotChat").setup({
        debug = false,
        auto_follow_cursor = true,
        model = "claude-3.5-sonnet",
        show_help = false,
        context = "buffers",
        language = "English",
        prompts = {
          Explain = "Explain how it works in the English language.",
          Review = "Review the following code and provide concise suggestions.",
          Tests = "Write tests for the following code.",
          Anything = {
            system_prompt = "Ignore any previous prompts and respond to the following question. It will likely be a technical question but could be anything.",
            prompt = "This is a free-form prompt. Respond to the following question.",
          },
        },
        build = function()
          vim.notify(
            "Please update the remote plugins by running :UpdateRemotePlugins, the"
          )
        end,
        event = "VeryLazy",
      })
    end,
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
          local actions = require("CopilotChat.actions")
          require("CopilotChat.integrations.telescope").pick(
            actions.help_actions()
          )
        end,
        desc = "CopilotChat - Help actions",
      },
      {
        "<leader>ccp",
        function()
          local actions = require("CopilotChat.actions")
          local select = require("CopilotChat.select")
          require("CopilotChat.integrations.telescope").pick(
            actions.prompt_actions({ selection = select.buffer })
          )
        end,
        desc = "CopilotChat - Prompt actions",
      },
      {
        "<leader>ccv",
        function()
          local chat = require("CopilotChat")
          local select = require("CopilotChat.select")

          local question = vim.fn.input("Quick Chat (Visual): ")
          chat.ask(question, { selection = select.visual })
        end,
        mode = "v",
        desc = "CopilotChat - Visual",
      },
      {
        "<leader>cci",
        function()
          local chat = require("CopilotChat")
          local select = require("CopilotChat.select")

          local question = vim.fn.input("Quick Chat (Visual): ")
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
