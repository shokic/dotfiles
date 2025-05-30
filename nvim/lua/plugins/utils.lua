return {
  {
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
  },
  {
    "ghillb/cybu.nvim",
    branch = "main",
    dependencies = { "nvim-lua/plenary.nvim", "kyazdani42/nvim-web-devicons" },
    config = function()
      require("cybu").setup({})

      vim.keymap.set("n", "K", "<Plug>(CybuPrev)")
      vim.keymap.set("n", "J", "<Plug>(CybuNext)")
    end,
  },
}
