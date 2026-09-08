return {
	"catppuccin/nvim",
	enabled = true,
	lazy = false,
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			-- No backgrounds: every window falls through to the terminal's own
			-- background, so Normal, floats, the completion menu and sidebars are
			-- uniformly flat and no border sits on a different shade than the body
			-- it encloses. Setting this false means also reconciling Pmenu (mantle)
			-- and NormalSB (crust) by hand, or those edges band against the border.
			transparent_background = true,
			background = { -- :h background
				light = "latte",
				dark = "mocha",
			},
			highlight_overrides = {
				mocha = function(mocha)
					-- transparent_background clears Normal but NOT float
					-- backgrounds: those stay on mantle, one shade off the
					-- terminal background. That darker rectangle is what reads
					-- as a "box" behind a border, and it bands against every
					-- group that *is* cleared. Clear the float family too so
					-- windows are uniformly flat and a border never encloses a
					-- different shade than its own frame.
					local flat = { bg = "NONE" }
					return {
						["@type.builtin"] = { link = "Keyword" }, -- primitive types
						NormalFloat = flat,
						FloatTitle = { bg = "NONE", fg = mocha.subtext0 },
						FloatFooter = { bg = "NONE", fg = mocha.subtext0 },
						FloatBorder = { bg = "NONE", fg = mocha.blue },
						NormalSB = flat,
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
