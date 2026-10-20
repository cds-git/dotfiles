return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{ "-", "<CMD>Oil<CR>", desc = "[Oil] Open parent directory" },
	},
	opts = {
		-- neo-tree handles opening directories (`nvim .`)
		default_file_explorer = false,
		columns = {
			"icon",
		},
		view_options = {
			-- Show files and directories that start with "."
			show_hidden = true,
		},
		keymaps = {
			-- defaults clash with window navigation (<C-h>/<C-l>) and save (<C-s>)
			["<C-h>"] = false,
			["<C-s>"] = false,
			["<C-l>"] = false,
			["<C-v>"] = "actions.select_vsplit",
			["<C-x>"] = "actions.select_split",
			["R"] = "actions.refresh",
		},
	},
}
