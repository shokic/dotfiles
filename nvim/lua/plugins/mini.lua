return {
  "echasnovski/mini.nvim",
  version = "*",
  config = function()
    require("mini.statusline").setup()
    require("mini.pairs").setup()
  end,
}
