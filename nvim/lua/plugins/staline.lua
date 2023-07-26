return {
    "tamton-aquib/staline.nvim",
    config = function()
        require("staline").setup({
            sections = {
                left = { "mode", "branch", "lsp" },
                mid = {},
                right = { "file_name", "line_column" },
            },
            mode_icons = {
                n = "N ",
                i = "I ",
                c = "C ",
                v = "V ",
            },
            mode_colors = {
                i = "#bbbbbb",
                n = "#bbbbbb",
                c = "#bbbbbb",
                v = "#bbbbbb",
            },
            lsp_symbols = {
                Error = " ",
                Warn = " ",
                Info = " ",
                Hint = " ",
            },
            defaults = {
                true_colors = true,
                line_column = "[%l/%L]",
                branch_symbol = "",
                mod_symbol = " ○ ",
            },
        })
    end,
}
