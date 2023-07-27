return {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    config = function()
        require("kanagawa").setup({
            statementStyle = { bold = false },
            keywordStyle = { italic = false },
            commentStyle = { italic = false },
            colors = {
                palette = {
                    dragonBlack3 = "#181818",
                    dragonBlack4 = "#181818",
                },
            },
        })
        vim.cmd.colorscheme("kanagawa-dragon")
    end,
}
