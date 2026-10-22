-- Diffs for history and conflicts. Reviewing changes (working tree, branch, commits)
-- goes through review.nvim, which drives codediff with these same options.
return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gh", "<cmd>CodeDiff history %<CR>", desc = "[CodeDiff] File history" },
		{ "<leader>gl", "<cmd>CodeDiff history<CR>", desc = "[CodeDiff] Repo history" },
		{
			"<leader>gx",
			function()
				-- `merge` does not expand %, so pass the path itself
				vim.cmd("CodeDiff merge " .. vim.fn.fnameescape(vim.fn.expand("%:p")))
			end,
			desc = "[CodeDiff] Resolve conflicts in file",
		},
	},
	opts = {
		diff = {
			layout = "inline", -- one buffer; `t` toggles side-by-side
			-- show moved blocks as moves rather than delete + insert
			compute_moves = true,
		},
		-- the explorer starts hidden; `f` in a review toggles it
		explorer = {
			hidden = true,
			initial_focus = "modified",
			width = 30,
			view_mode = "tree",
		},
		keymaps = {
			view = {
				-- defaults are <leader>b (Snipe) and <leader>e (neo-tree)
				toggle_explorer = false,
				focus_explorer = false,
			},
		},
	},
	config = function(_, opts)
		require("codediff").setup(opts)

		local explorer = require("codediff.ui.explorer")

		-- Upstream bug: navigate_next/prev call nvim_win_is_valid(nil) when the explorer
		-- has never been shown (hidden = true). An invalid id makes them skip the cursor sync.
		for _, name in ipairs({ "navigate_next", "navigate_prev" }) do
			local navigate = explorer[name]
			explorer[name] = function(e)
				if e.winid == nil then
					e.winid = -1
				end
				return navigate(e)
			end
		end
	end,
}
