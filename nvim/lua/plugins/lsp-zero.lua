return {
    { "williamboman/mason.nvim" },

    { "williamboman/mason-lspconfig.nvim" },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "hrsh7th/cmp-nvim-lsp" },
            { "folke/neodev.nvim" },
            {
                "j-hui/fidget.nvim",
                tag = "legacy",
                opts = {},
            },
        },
    },

    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            { "L3MON4D3/LuaSnip" },
        },
    },

    {
        "VonHeikemen/lsp-zero.nvim",
        dependencies = { "onsails/lspkind.nvim" },
        branch = "dev-v3",
        config = function()
            local lsp = require("lsp-zero").preset({})

            lsp.on_attach(function(client, bufnr)
                lsp.default_keymaps({ buffer = bufnr })
            end)

            lsp.format_mapping("F", {
                format_opts = {
                    async = false,
                    timeout_ms = 10000,
                },
                servers = {
                    ["null-ls"] = { "javascript", "typescript", "lua" },
                },
            })

            lsp.extend_cmp()

            require("mason").setup({})
            require("mason-lspconfig").setup({
                ensure_installed = { "tsserver", "lua_ls" },
                handlers = {
                    lsp.default_setup,
                },
            })

            local cmp = require("cmp")
            local cmp_action = require("lsp-zero").cmp_action()

            local lspkind = require("lspkind")
            lspkind.init({
                symbol_map = {
                    Copilot = "",
                },
            })

            vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

            cmp.setup({
                sources = {
                    { name = "copilot" },
                    { name = "nvim_lsp" },
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = {
                    ["<Tab>"] = cmp_action.luasnip_supertab(),
                    ["<S-Tab>"] = cmp_action.luasnip_shift_supertab(),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                },
                formatting = {
                    fields = { "abbr", "kind", "menu" },
                    format = lspkind.cmp_format({
                        mode = "symbol",
                        maxwidth = 150,
                        ellipsis_char = "...",
                    }),
                },
            })
        end,
    },
}
