return {
  "echasnovski/mini.nvim",
  version = "*",
  config = function()
    require("mini.icons").setup()
    require("mini.pairs").setup()
    require("mini.ai").setup({ n_lines = 500 })
    require("mini.surround").setup()
    require("mini.comment").setup()

    local statusline = require("mini.statusline")
    statusline.setup()

    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return "%l/%L:%v"
    end
  end,
}
