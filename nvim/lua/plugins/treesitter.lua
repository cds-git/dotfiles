return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")
			configs.setup({
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				ensure_installed = {
					"lua",
					"luadoc",
					"luap",
					"c_sharp",
					"vim",
					"css",
					"javascript",
					"typescript",
					"scss",
					"json",
					"html",
					"markdown",
					"regex",
					"bash",
					"markdown_inline",
					"angular",
				},
			})
		end,
	},
}
