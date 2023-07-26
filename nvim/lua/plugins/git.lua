return {
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
        },
        config = function()
            local gitsigns = require("gitsigns")

            gitsigns.setup({
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns

                    vim.keymap.set(
                        "n",
                        "<leader>B",
                        gs.toggle_current_line_blame,
                        { buffer = bufnr }
                    )
                end,
            })
        end,
    },

    {
        "TimUntersberger/neogit",
        dependencies = "nvim-lua/plenary.nvim",
        config = function()
            local neogit = require("neogit")

            neogit.setup({
                integrations = {
                    diffview = true,
                },
            })

            vim.keymap.set("n", "<leader>gg", ":Neogit<CR>")
        end,
    },

    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            vim.keymap.set("n", "<leader>gd", ":DiffviewOpen<CR>")
            vim.keymap.set("n", "<leader>gb", ":DiffviewToggleFiles<CR>")
            vim.keymap.set("n", "<leader>gq", ":DiffviewClose<CR>")
        end,
    },
}
