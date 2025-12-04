return {
	"mikavilpas/yazi.nvim",
	event = "VeryLazy",
	opts = {
		-- Configuration will use your existing yazi config
		open_for_directories = false, -- Let neo-tree handle directory opening
		keymaps = {
			show_help = "<f1>",
		},
	},
	config = function(_, opts)
		require("yazi").setup(opts)

		vim.keymap.set("n", "-", "<cmd>Yazi<CR>", { desc = "[Yazi] Open file manager" })
		vim.keymap.set("n", "<leader>-", "<cmd>Yazi cwd<CR>", { desc = "[Yazi] Open file manager in cwd" })
	end,
}
