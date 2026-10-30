-- Rex config, in Lua: shortcuts (rex.bind, rex.mode), custom actions (rex.action),
-- layouts (rex.layout), and other servers (rex.host). Fonts and themes are set in the app.
-- Rex doesn't watch this file: run `rex config reload` after changing it, `rex config check` to test it.
-- Other Lua files next to this one can be loaded with require("name").
-- Docs: https://superlogical.com/rex/docs/customize/config, API: https://superlogical.com/rex/docs/reference/lua

-- Example: split the pane to the right with cmd+d
-- rex.bind("cmd+d", "pane.split", { direction = "right" })
