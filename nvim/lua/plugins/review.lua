-- Annotate a diff with comments and export them as markdown (e.g. to hand to an AI agent).
-- Opening a review lives under <leader>g with the rest of git.

local function current_branch()
	return vim.fn.systemlist({ "git", "rev-parse", "--abbrev-ref", "HEAD" })[1]
end

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
		{ "<leader>gd", "<cmd>Review<CR>", desc = "[Review] Uncommitted changes" },
		{
			"<leader>gm",
			function()
				-- current branch (with uncommitted work) against origin/HEAD, main or master; no picker
				require("review").open_branch(current_branch())
			end,
			desc = "[Review] Branch vs main (PR diff)",
		},
		{
			"<leader>gb",
			function()
				-- current branch against a picked base, e.g. a release branch
				local current = current_branch()
				Snacks.picker.git_branches({
					all = true,
					title = "Review " .. current .. " against",
					confirm = function(picker, item)
						picker:close()
						if item and item.branch then
							require("review").open_branch(current, item.branch)
						end
					end,
				})
			end,
			desc = "[Review] Branch vs picked base",
		},
		{ "<leader>gc", "<cmd>Review commits<CR>", desc = "[Review] Commits" },
		-- ":" rather than <cmd> so the same key takes a visual range. Editing, deleting
		-- and exporting comments are single keys inside a review (e, d, C, q).
		{ "<leader>gn", ":Review note<CR>", mode = { "n", "v" }, desc = "[Review] Note here" },
	},
	opts = {},
}
