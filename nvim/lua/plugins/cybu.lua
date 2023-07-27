return {
    "ghillb/cybu.nvim",
    branch = "main",
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim" },
    config = function()
        local ok, cybu = pcall(require, "cybu")
        if not ok then
            return
        end
        cybu.setup({
            display_time = 750,
            behavior = {
                mode = {
                    default = {
                        switch = "immediate",
                        view = "rolling",
                    },
                    last_used = {
                        switch = "immediate",
                        view = "paging",
                    },
                    auto = {
                        view = "rolling",
                    },
                },
                show_on_autocmd = false,
            },
        })

        vim.keymap.set("n", "U", "<Plug>(CybuPrev)")
        vim.keymap.set("n", "I", "<Plug>(CybuNext)")
        vim.keymap.set("n", "<s-tab>", "<plug>(CybuLastusedPrev)")
        vim.keymap.set("n", "<tab>", "<plug>(CybuLastusedNext)")
    end,
}
