local lspconfig = require("lspconfig")
lspconfig.lua_ls.setup({
    settings = {
        globals = { "vim" },
    },
    ft = ".lua",
})
