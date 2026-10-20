-- Pins the enclosing class/method signatures to the top of the window while scrolling
return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPost", "BufNewFile" },
	keys = {
		{ "<leader>ut", "<cmd>TSContext toggle<CR>", desc = "Toggle Treesitter Context" },
	},
	opts = {
		-- namespace + class + method is as deep as it needs to go
		max_lines = 3,
		-- a long multi-line signature collapses to its first line
		multiline_threshold = 1,
	},
}
