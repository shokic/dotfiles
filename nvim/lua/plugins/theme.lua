return {
  {
    "rebelot/kanagawa.nvim",
    config = function()
      local theme = require("kanagawa")

      theme.setup({
        keywordStyle = { italic = false },
        statementStyle = { bold = true, italic = false },
        commentStyle = { italic = false },
        colors = {
          palette = {
            dragonBlack4 = "#1F1C1C",
            dragonBlack6 = "#272523",
          },
        },
      })

      vim.cmd("colorscheme kanagawa-dragon")
    end,
  },
}
