return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup {
        messages = {
          enabled = false,
        },
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        cmdline = {
          enabled = true,
        },
        views = {
          cmdline_popup = {
            enabled = false,
          },
        },
        presets = {
          bottom_search = false,
          command_palette = false,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
      }
    end,
  },
  {
    "NvChad/nvim-colorizer.lua",
    ft = { "python" },
    config = function()
      require("colorizer").setup {}
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function() end,
  },
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   dependencies = { "nvim-tree/nvim-web-devicons" },
  --   config = function()
  --     require("lualine").setup({
  --       options = {
  --         theme = "gruvbox",
  --         -- section_separators = { "", "" },
  --         -- component_separators = { "", "" },
  --       section_separators = { "", "" },
  --       component_separators = { "", "" },
  --         globalstatus = true,
  --       },
  --       sections = {
  --         lualine_c = { { "filename", path = 1 } },
  --         lualine_y = {
  --           { require("recorder").displaySlots },
  --         },
  --         lualine_z = {
  --           { require("recorder").recordingStatus },
  --         },
  --       },
  --     })
  --   end,
  -- },
  {
    "rcarriga/nvim-notify",
    lazy = true,
    config = function()
      vim.api.nvim_set_keymap(
        "n",
        "<leader>nd",
        ":lua require('notify').dismiss()<CR>",
        { noremap = true, silent = true }
      )

      require("notify").setup {
        background_colour = "#000000",
        fps = 30,
        icons = {
          DEBUG = "",
          ERROR = "",
          INFO = "",
          TRACE = "✎",
          WARN = "",
        },
        level = 2,
        minimum_width = 50,
        maximum_width = 300,
        render = "compact",
        stages = "fade_in_slide_out",
        timeout = 5000,
        top_down = true,
      }
    end,
  },
}
