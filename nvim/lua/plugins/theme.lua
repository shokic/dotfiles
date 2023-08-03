return {
    "catppuccin/nvim",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "mocha",
            no_italic = true,
            no_bold = true,
            color_overrides = {
                all = {
                    base = "#1f1f1f",
                },
            },
        })
        vim.cmd.colorscheme("catppuccin")
    end,
}
