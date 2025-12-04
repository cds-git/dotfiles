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
				cmp = true,
				blink_cmp = true,
				gitsigns = true,
				neotest = true,
				neotree = true,
				treesitter = true,
				treesitter_context = true,
				which_key = true,
				semantic_tokens = true,
				snacks = true,
				notify = true,
				noice = true,
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
