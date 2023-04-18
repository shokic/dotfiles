return {
  "rebelot/kanagawa.nvim",
  config = function()
    local theme = require("kanagawa")

    theme.setup({
      keywordStyle = { italic = false },
      statementStyle = { bold = true, italic = false },
      commentStyle = { italic = false },
      colors = {
        palette = {
          dragonBlack3 = "#1e2021",
          dragonBlack4 = "#1e2021",
          dragonBlack6 = "#2B2927",
        },
      },
    })

    vim.cmd("colorscheme kanagawa-dragon")
  end,
}
