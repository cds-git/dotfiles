-- Base branch for "what does my PR change": origin/HEAD, falling back to main/master
local function base_branch()
	local ref = vim.fn.systemlist("git symbolic-ref --short refs/remotes/origin/HEAD")[1]
	if vim.v.shell_error == 0 and ref and ref ~= "" then
		return ref
	end
	for _, candidate in ipairs({ "origin/main", "origin/master", "main", "master" }) do
		vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", candidate })
		if vim.v.shell_error == 0 then
			return candidate
		end
	end
	return "main"
end

-- merge-base of the branch vs working tree: the PR as it stands, including uncommitted work
local function compare_with(branch)
	vim.cmd("CodeDiff " .. branch .. "...")
end

-- Pick one of the current CodeDiff tab's changed files with snacks; replaces the explorer
local function pick_changed_file()
	local e = require("codediff.ui.lifecycle").get_panel_view(vim.api.nvim_get_current_tabpage())
	if not (e and e.tree) then
		vim.notify("No CodeDiff explorer in this tab", vim.log.levels.WARN)
		return
	end
	local items = {}
	for _, file in ipairs(require("codediff.ui.explorer.tree").get_all_files(e.tree)) do
		local data = file.data
		table.insert(items, {
			text = data.path,
			file = vim.fs.joinpath(data.git_root or e.git_root, data.path),
			current = data.path == e.data.current_file_path and data.group == e.data.current_file_group,
			data = data,
		})
	end
	Snacks.picker.pick({
		title = "Changed files",
		items = items,
		format = "file",
		preview = "file",
		on_show = function(picker)
			for i, item in ipairs(picker:items()) do
				if item.current then
					picker.list:view(i)
					break
				end
			end
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				e.on_file_select(item.data)
			end
		end,
	})
end

return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gd", "<cmd>CodeDiff<CR>", desc = "[CodeDiff] Working tree changes" },
		{ "<leader>gf", pick_changed_file, desc = "[CodeDiff] Pick changed file" },
		{
			"<leader>gc",
			function()
				Snacks.picker.git_log({
					title = "Review commit",
					confirm = function(picker, item)
						picker:close()
						if item and item.commit then
							-- parent vs commit: exactly what that commit changed
							vim.cmd("CodeDiff " .. item.commit .. "^ " .. item.commit)
						end
					end,
				})
			end,
			desc = "[CodeDiff] Review a commit",
		},
		{
			"<leader>ge",
			function()
				local e = require("codediff.ui.lifecycle").get_panel_view(vim.api.nvim_get_current_tabpage())
				if not (e and e.split) then
					vim.notify("No CodeDiff explorer in this tab", vim.log.levels.WARN)
					return
				end
				require("codediff.ui.explorer").toggle_visibility(e)
				if not e.is_hidden and vim.api.nvim_win_is_valid(e.winid) then
					vim.api.nvim_set_current_win(e.winid)
				end
			end,
			desc = "[CodeDiff] Toggle changed files sidebar",
		},
		{
			"<leader>gm",
			function()
				compare_with(base_branch())
			end,
			desc = "[CodeDiff] Compare with default branch (PR diff)",
		},
		{
			"<leader>gb",
			function()
				Snacks.picker.git_branches({
					all = true,
					title = "Compare with branch",
					confirm = function(picker, item)
						picker:close()
						if item and item.branch then
							compare_with(item.branch)
						end
					end,
				})
			end,
			desc = "[CodeDiff] Compare with branch...",
		},
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
		-- the explorer starts hidden; <leader>ge toggles it, <leader>gf picks files with snacks
		explorer = {
			hidden = true,
			initial_focus = "modified",
			width = 30,
			view_mode = "tree",
		},
		keymaps = {
			view = {
				-- defaults are <leader>b (Snipe) and <leader>e (neo-tree); <leader>ge replaces both
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
