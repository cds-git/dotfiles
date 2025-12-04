return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		columns = {
			"icon",
		},
		view_options = {
			-- Show files and directories that start with "."
			show_hidden = true,
		},
		-- use_default_keymaps = false,
		keymaps = {
			["<C-h>"] = false,
			["<C-s>"] = false,
			["<C-l>"] = false,
			["<leader>sk"] = "actions.select_split",
			["<leader>sh"] = "actions.select_vsplit",
			["<leader>ro"] = "actions.refresh",
		},
	},
	config = function(_, opts)
		require("oil").setup(opts)

		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "[Oil] Open parent directory" })
	end,
}
