return {
  {
    "rebelot/kanagawa.nvim",
    config = function()
      local theme = require("kanagawa")

      theme.setup({
        keywordStyle = { italic = false },
        statementStyle = { bold = false },
      })

      vim.cmd("colorscheme kanagawa-dragon")
    end,
  },
}
