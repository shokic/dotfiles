return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "mocha",
            no_italic = true,
            no_bold = true,
            color_overrides = {
                all = {
                    base = "#181818",
                },
            },
            integrations = {
                mason = true,
                neotree = true,
                neogit = true,
                cmp = true,
                lsp_trouble = true,
                which_key = true,
                telescope = {
                    enabled = true,
                    style = "nvchad",
                },
                indent_blankline = {
                    enabled = true,
                    colored_indent_levels = false,
                },
            },
        })
        vim.cmd.colorscheme("catppuccin")
    end,
}
