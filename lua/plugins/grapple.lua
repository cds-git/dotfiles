return {
	"cbochs/grapple.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons", lazy = true },
	},
	opts = {
		scope = "git", -- also try out "git_branch"
	},
	event = { "BufReadPost", "BufNewFile" },
	cmd = "Grapple",
	keys = {
		{ "<leader>m", "<cmd>Grapple toggle<cr>", desc = "[Grapple] toggle tag" },
		{ "<leader>M", "<cmd>Grapple toggle_tags<cr>", desc = "[Grapple] open tags window" },
		{ "<leader>1", "<cmd>Grapple select index=1<cr>", desc = "which_key_ignore" },
		{ "<leader>2", "<cmd>Grapple select index=2<cr>", desc = "which_key_ignore" },
		{ "<leader>3", "<cmd>Grapple select index=3<cr>", desc = "which_key_ignore" },
		{ "<leader>4", "<cmd>Grapple select index=4<cr>", desc = "which_key_ignore" },
		{ "<leader>5", "<cmd>Grapple select index=5<cr>", desc = "which_key_ignore" },
		{ "<leader>6", "<cmd>Grapple select index=6<cr>", desc = "which_key_ignore" },
		{ "<leader>7", "<cmd>Grapple select index=7<cr>", desc = "which_key_ignore" },
		{ "<leader>8", "<cmd>Grapple select index=8<cr>", desc = "which_key_ignore" },
		{ "<leader>9", "<cmd>Grapple select index=9<cr>", desc = "which_key_ignore" },
	},
}
