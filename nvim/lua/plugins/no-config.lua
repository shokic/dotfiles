return {
    { "lukas-reineke/indent-blankline.nvim", opts = {} },

    { "tpope/vim-sleuth" },

    { "folke/which-key.nvim", opts = {} },

    { "m4xshen/autoclose.nvim", opts = {} },

    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
    },

    {
        "utilyre/barbecue.nvim",
        name = "barbecue",
        version = "*",
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {},
    },
}
