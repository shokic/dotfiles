return {
  "stevearc/oil.nvim",
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  config = function()
    require("oil").setup({
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
      },
      is_always_hidden = function(name, _)
        return name == ".git"
      end,
    })

    local actions = require("oil.actions")

    vim.keymap.set("n", "-", actions.parent.callback, { desc = "Open parent directory" })
    vim.keymap.set("n", "_", actions.open_cwd.callback, { desc = "Open project directory" })
  end,
}
