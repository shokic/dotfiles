if vim.g.vscode then
else
  require("config.settings")
  require("config.autocmds")
  require("config.keymaps")
  require("config.lazy")
end

