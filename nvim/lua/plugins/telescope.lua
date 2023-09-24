return {
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
    },

    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local builtin = require("telescope.builtin")
            local themes = require("telescope.themes")

            telescope.setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-u>"] = false,
                            ["<C-d>"] = false,
                        },
                        n = {
                            ["d"] = actions.delete_buffer,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        find_command = {
                            "rg",
                            "--files",
                            "--hidden",
                            "-g",
                            "!.git",
                        },
                        hidden = true,
                    },
                },
            })

            telescope.load_extension("fzf")

            vim.keymap.set("n", "<leader>,", function()
                builtin.oldfiles(themes.get_dropdown({
                    winblend = 10,
                    previewer = false,
                }))
            end, { desc = "[?] Find recently opened files" })

            vim.keymap.set(
                "n",
                "<leader><space>",
                builtin.buffers,
                { desc = "[ ] Find existing buffers" }
            )

            vim.keymap.set("n", "<leader>/", function()
                builtin.current_buffer_fuzzy_find(themes.get_dropdown({
                    winblend = 10,
                    previewer = false,
                }))
            end, { desc = "[/] Fuzzily search in current buffer" })

            vim.keymap.set(
                "n",
                "<leader>sf",
                builtin.find_files,
                { desc = "[S]earch [F]iles" }
            )

            vim.keymap.set(
                "n",
                "<leader>sh",
                builtin.help_tags,
                { desc = "[S]earch [H]elp" }
            )

            vim.keymap.set(
                "n",
                "<leader>sw",
                builtin.grep_string,
                { desc = "[S]earch current [W]ord" }
            )

            vim.keymap.set(
                "n",
                "<leader>sg",
                builtin.live_grep,
                { desc = "[S]earch by [G]rep" }
            )

            vim.keymap.set(
                "n",
                "<leader>sd",
                builtin.diagnostics,
                { desc = "[S]earch [D]iagnostics" }
            )
        end,
    },
}
