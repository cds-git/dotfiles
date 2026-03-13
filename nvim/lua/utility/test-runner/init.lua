local state = require("utility.test-runner.state")
local runner = require("utility.test-runner.runner")
local ui = require("utility.test-runner.ui")

local M = {}

--- Open the test runner, discover tests if not yet done
function M.open()
	ui.setup_highlights()
	ui.open()

	-- If we haven't discovered yet, do it now
	if not state.root_id then
		M.discover()
	end
end

--- Toggle the test runner window
function M.toggle()
	ui.setup_highlights()
	if ui.is_open() then
		ui.close()
	else
		M.open()
	end
end

--- Start discovery from a chosen path
---@param search_dir string
---@param root_name string
local function do_discover(search_dir, root_name)
	state.sln_path = search_dir
	state.clear()

	-- Show a temporary "discovering" state
	state.register({
		id = "root:" .. search_dir,
		display_name = root_name .. " (discovering...)",
		type = state.Type.SOLUTION,
		status = state.Status.DISCOVERING,
		expanded = true,
		parent_id = nil,
	})
	state.root_id = "root:" .. search_dir
	ui.refresh()

	runner.discover(search_dir, root_name, function()
		ui.refresh()
		local counts = state.counts()
		vim.notify(string.format("Found %d tests", counts.total), vim.log.levels.INFO)
	end)
end

--- Discover tests (finds solution or falls back to cwd)
function M.discover()
	local solutions = runner.find_solutions()

	if #solutions == 0 then
		-- No solution file — scan from cwd directly
		local cwd = vim.fn.getcwd()
		local root_name = vim.fn.fnamemodify(cwd, ":t")
		do_discover(cwd, root_name)
		return
	end

	if #solutions == 1 then
		local sln = solutions[1]
		do_discover(vim.fn.fnamemodify(sln, ":h"), vim.fn.fnamemodify(sln, ":t"))
		return
	end

	-- Multiple solutions - let user pick via Snacks
	Snacks.picker({
		title = "Select Solution",
		items = vim.tbl_map(function(path)
			return { text = vim.fn.fnamemodify(path, ":t"), item = path }
		end, solutions),
		format = function(item)
			return { { item.text, "Normal" } }
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				local sln = item.item
				do_discover(vim.fn.fnamemodify(sln, ":h"), vim.fn.fnamemodify(sln, ":t"))
			end
		end,
	})
end

--- Run the test nearest to cursor in the current .cs buffer
function M.run_nearest()
	ui.setup_highlights()

	if vim.bo.filetype ~= "cs" then
		vim.notify("Not a C# file", vim.log.levels.WARN)
		return
	end

	-- Get current method name using treesitter
	local method_name = nil
	local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
	if ok then
		local node = ts_utils.get_node_at_cursor()
		while node do
			if node:type() == "method_declaration" then
				-- Find the method name child
				for child in node:iter_children() do
					if child:type() == "identifier" then
						method_name = vim.treesitter.get_node_text(child, 0)
						break
					end
				end
				break
			end
			node = node:parent()
		end
	end

	if not method_name then
		-- Fallback: parse current line for method pattern
		local line = vim.api.nvim_get_current_line()
		method_name = line:match("public%s+%w+%s+(%w+)%s*%(")
			or line:match("void%s+(%w+)%s*%(")
			or line:match("async%s+%w+%s+(%w+)%s*%(")
	end

	if not method_name then
		vim.notify("Could not find test method at cursor", vim.log.levels.WARN)
		return
	end

	-- If we have state, find the matching test node
	if state.root_id then
		for _, n in pairs(state.nodes) do
			if n.type == state.Type.TEST and n.fqn then
				local parsed = runner.parse_test_name(n.fqn)
				local base_method = parsed.method:match("^([^%(]+)")
				if base_method == method_name then
					if not ui.is_open() then
						ui.open()
					end
					-- Expand parents so we can see the result
					local walk = n
					while walk.parent_id do
						local parent = state.get(walk.parent_id)
						if parent then
							parent.expanded = true
						end
						walk = parent
					end
					runner.run(n)
					return
				end
			end
		end
	end

	-- No state yet - discover first, then try to run
	vim.notify("Discovering tests first...", vim.log.levels.INFO)
	if not ui.is_open() then
		M.open()
	else
		M.discover()
	end
end

--- Setup commands and keymaps
function M.setup()
	ui.setup_highlights()

	vim.api.nvim_create_user_command("DotnetTestRunner", function()
		M.toggle()
	end, { desc = "Toggle .NET test runner" })

	vim.api.nvim_create_user_command("DotnetTestRun", function()
		M.run_nearest()
	end, { desc = "Run nearest .NET test" })

	vim.api.nvim_create_user_command("DotnetTestDiscover", function()
		if not ui.is_open() then
			ui.open()
		end
		M.discover()
	end, { desc = "Discover .NET tests" })
end

return M
