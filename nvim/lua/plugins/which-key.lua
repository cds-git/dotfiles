return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	-- timeoutlen is set in options.lua (300ms)
	opts = {},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = true })
			end,
			desc = "Show All Keymaps (which-key)",
		},
	},
}
