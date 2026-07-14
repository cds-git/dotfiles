return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
	},
	opts = {
		filesystem = {
			use_libuv_file_watcher = true, -- auto-refresh on external file changes
		},
	},
	config = function(_, opts)
		require("neo-tree").setup(opts)

		vim.keymap.set(
			"n",
			"<leader>e",
			"<cmd>Neotree filesystem reveal left<CR>",
			{ desc = "Go to current buffer in NeoTree explorer" }
		)
		vim.keymap.set("n", "<C-n>", "<cmd>Neotree toggle<CR>", { desc = "Toggle NeoTree explorer" })
	end,
}
