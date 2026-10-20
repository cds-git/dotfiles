-- Annotate a diff with comments and export them as markdown (e.g. to hand to an AI agent).
-- Lives under <leader>v because <leader>r is rename/restart.
return {
	"georgeguimaraes/review.nvim",
	version = "*",
	dependencies = {
		"esmuellert/codediff.nvim",
		"MunifTanjim/nui.nvim",
	},
	-- loaded early so notes from earlier sessions show when a file is opened
	event = "VeryLazy",
	keys = {
		{ "<leader>vr", "<cmd>Review<CR>", desc = "[Review] Working tree" },
		{ "<leader>vb", "<cmd>Review branch<CR>", desc = "[Review] Branch vs base" },
		{ "<leader>vc", "<cmd>Review commits<CR>", desc = "[Review] Commits" },
		-- ":" rather than <cmd> so the same key takes a visual range
		{ "<leader>vn", ":Review note<CR>", mode = { "n", "v" }, desc = "[Review] Note here" },
		{ "<leader>ve", "<cmd>Review edit<CR>", desc = "[Review] Edit comment" },
		{ "<leader>vd", "<cmd>Review delete<CR>", desc = "[Review] Delete comment" },
		{ "<leader>vl", "<cmd>Review list<CR>", desc = "[Review] List comments" },
		{ "<leader>vp", "<cmd>Review preview<CR>", desc = "[Review] Preview export" },
		{ "<leader>vx", "<cmd>Review export<CR>", desc = "[Review] Export to clipboard" },
		{ "<leader>vq", "<cmd>Review close<CR>", desc = "[Review] Close (export + archive)" },
	},
	opts = {},
}
