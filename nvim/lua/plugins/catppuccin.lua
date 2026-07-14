return {
	"catppuccin/nvim",
	enabled = true,
	lazy = false,
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = true, -- disables setting the background color
			background = { -- :h background
				light = "latte",
				dark = "mocha",
			},
			highlight_overrides = {
				mocha = function(mocha)
					return {
						["@type.builtin"] = { link = "Keyword" }, -- primitive types
					}
				end,
			},
			integrations = {
				blink_cmp = true,
				gitsigns = true,
				neotree = true,
				treesitter = true,
				treesitter_context = true,
				which_key = true,
				semantic_tokens = true,
				snacks = true,
				dap = true,
				dap_ui = true,
				mason = true,
				render_markdown = true,
				diffview = true,
				grug_far = true,
				nvim_surround = true,
				dadbod_ui = true,
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
