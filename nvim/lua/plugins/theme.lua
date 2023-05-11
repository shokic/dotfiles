return {
  "rebelot/kanagawa.nvim",
  config = function()
    require("kanagawa").setup({
      background = {
        dark = "dragon",
        light = "lotus",
      },

      functionStyle = {},
      keywordStyle = { italic = false },
      statementStyle = {},

      colors = {
        palette = {
          dragonBlack3 = "#1f1f1f",
          dragonBlack4 = "#1f1f1f",
          dragonBlack6 = "#393734",
        },
      },

      overrides = function(colors)
        local theme = colors.theme
        return {
          NormalFloat = { bg = theme.ui.bg_p2 },
          FloatBorder = { bg = "none" },
          FloatTitle = { bg = "none" },
          TelescopeTitle = { fg = theme.ui.special, bold = true },
          TelescopePromptNormal = { bg = theme.ui.bg_p2 },
          TelescopePromptBorder = { fg = theme.ui.bg_p2, bg = theme.ui.bg_p2 },
          TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
          TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
          TelescopePreviewNormal = { bg = theme.ui.bg_dim },
          TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
        }
      end,
    })

    vim.cmd("colorscheme kanagawa")
  end,
}
