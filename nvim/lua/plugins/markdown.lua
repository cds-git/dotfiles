return {
	-- In-buffer markdown rendering (headings, code blocks, tables, checkboxes,
	-- callouts, etc). Renders in normal mode and reveals raw text on the line
	-- the cursor is on / in insert mode. No browser needed -- works in the
	-- terminal, unlike the old browser-based markdown-preview.nvim.
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	ft = { "markdown" },
	opts = {},
	keys = {
		{ "<leader>mp", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown render" },
	},
}
