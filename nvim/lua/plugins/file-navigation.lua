-- Move around windows with vim keys
for direction, key in pairs({ h = "h", j = "j", k = "k", l = "l" }) do
  vim.keymap.set("n", "<leader>" .. key, function()
    vim.cmd.wincmd(key)
  end, { desc = "Move to " .. direction .. " window" })
end

return {
  { "nanotee/zoxide.vim", cmd = { "Lz" } },
  {
    "stevearc/oil.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    keys = {
      { "-", mode = "n", "<CMD>Oil<CR>", desc = "Oil - Open parent directory" },
    },
    config = function()
      require("oil").setup({
        view_options = {
          show_hidden = true,
        },
      })
    end,
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>a", desc = "Harpoon add file" },
      { "<C-e>", desc = "Harpoon menu" },
    },
    config = function()
      local harpoon = require("harpoon")

      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end)
      vim.keymap.set("n", "<C-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      -- Number keys (1-4)
      local number_keys = { "<leader>1", "<leader>2", "<leader>3", "<leader>4" }
      for i, key in ipairs(number_keys) do
        vim.keymap.set("n", key, function()
          harpoon:list():select(i)
        end)
      end

      -- Control keys
      local ctrl_keys = {
        ["h"] = 1,
        ["t"] = 2,
        ["w"] = 3,
        ["s"] = 4,
      }
      for key, index in pairs(ctrl_keys) do
        vim.keymap.set("n", "<C-" .. key .. ">", function()
          harpoon:list():select(index)
        end)
      end

      harpoon:setup({})
    end,
  },
}
