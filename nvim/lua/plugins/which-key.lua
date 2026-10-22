return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	-- timeoutlen is set in options.lua (300ms)
	opts = {
		spec = {
			{ "<leader>c", group = "code" },
			{ "<leader>d", group = "debug" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>h", group = "hunks" },
			{ "<leader>l", group = "lsp" },
			{ "<leader>r", group = "rename/restart" },
			{ "<leader>s", group = "search" },
			{ "<leader>t", group = "test" },
			{ "<leader>u", group = "ui/toggle" },
			{ "<leader>w", group = "workspace" },
		},
	},
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
