local M = {}

-- Lazy-load heavy modules only when needed
local _state, _runner, _ui

local function state()
	if not _state then
		_state = require("utility.test-runner.state")
	end
	return _state
end

local function runner()
	if not _runner then
		_runner = require("utility.test-runner.runner")
	end
	return _runner
end

local function ui()
	if not _ui then
		_ui = require("utility.test-runner.ui")
	end
	return _ui
end

--- Open the test runner, discover tests if not yet done
function M.open()
	ui().setup_highlights()
	ui().open()

	-- If we haven't discovered yet, do it now
	if not state().root_id then
		M.discover()
	end
end

--- Toggle the test runner window
function M.toggle()
	ui().setup_highlights()
	if ui().is_open() then
		ui().close()
	else
		M.open()
	end
end

--- Start discovery from a chosen path
---@param search_dir string
---@param root_name string
local function do_discover(search_dir, root_name)
	state().sln_path = search_dir
	state().clear()

	-- Show a temporary "discovering" state
	state().register({
		id = "root:" .. search_dir,
		display_name = root_name .. " (discovering...)",
		type = state().Type.SOLUTION,
		status = state().Status.DISCOVERING,
		expanded = true,
		parent_id = nil,
	})
	state().root_id = "root:" .. search_dir
	ui().refresh()

	runner().discover(search_dir, root_name, function()
		ui().refresh()
		local counts = state().counts()
		vim.notify(string.format("Found %d tests", counts.total), vim.log.levels.INFO)
	end)
end

--- Discover tests (finds solution or falls back to cwd)
function M.discover()
	local solutions = runner().find_solutions()

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

--- Find the test method name at cursor using treesitter with regex fallback
---@return string|nil
local function find_method_at_cursor()
	if vim.bo.filetype ~= "cs" then
		vim.notify("Not a C# file", vim.log.levels.WARN)
		return nil
	end

	local method_name = nil
	local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
	if ok then
		local node = ts_utils.get_node_at_cursor()
		while node do
			if node:type() == "method_declaration" then
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
		local line = vim.api.nvim_get_current_line()
		method_name = line:match("public%s+%w+%s+(%w+)%s*%(")
			or line:match("void%s+(%w+)%s*%(")
			or line:match("async%s+%w+%s+(%w+)%s*%(")
	end

	if not method_name then
		vim.notify("Could not find test method at cursor", vim.log.levels.WARN)
	end
	return method_name
end

--- Find the test node matching a method name
---@param method_name string
---@return TestNode|nil
local function find_test_node(method_name)
	if not state().root_id then
		return nil
	end
	for _, n in pairs(state().nodes) do
		if n.type == state().Type.TEST and n.fqn then
			local parsed = runner().parse_test_name(n.fqn)
			local base_method = parsed.method:match("^([^%(]+)")
			if base_method == method_name then
				return n
			end
		end
	end
	return nil
end

--- Expand parents of a node so it's visible in the tree
---@param node TestNode
local function expand_parents(node)
	local walk = node
	while walk.parent_id do
		local parent = state().get(walk.parent_id)
		if parent then
			parent.expanded = true
		end
		walk = parent
	end
end

--- Run the test nearest to cursor in the current .cs buffer
function M.run_nearest()
	ui().setup_highlights()

	local method_name = find_method_at_cursor()
	if not method_name then
		return
	end

	local test_node = find_test_node(method_name)
	if test_node then
		if not ui().is_open() then
			ui().open()
		end
		expand_parents(test_node)
		runner().run(test_node)
		return
	end

	-- No state yet - discover first, then try to run
	vim.notify("Discovering tests first...", vim.log.levels.INFO)
	if not ui().is_open() then
		M.open()
	else
		M.discover()
	end
end

--- Debug the test nearest to cursor in the current .cs buffer
function M.debug_nearest()
	ui().setup_highlights()

	local method_name = find_method_at_cursor()
	if not method_name then
		return
	end

	local test_node = find_test_node(method_name)
	if test_node then
		ui().debug_test(test_node)
		return
	end

	-- No state yet - discover first
	vim.notify("Discovering tests first... try again after discovery completes", vim.log.levels.INFO)
	if not ui().is_open() then
		M.open()
	else
		M.discover()
	end
end

--- Open the test runner with the nearest test focused/selected
function M.focus_nearest()
	ui().setup_highlights()

	local method_name = find_method_at_cursor()
	if not method_name then
		return
	end

	local test_node = find_test_node(method_name)
	if test_node then
		expand_parents(test_node)
		if not ui().is_open() then
			ui().open()
		end
		ui().refresh()
		ui().focus_node(test_node.id)
		return
	end

	-- No state yet - discover first
	vim.notify("Discovering tests first...", vim.log.levels.INFO)
	if not ui().is_open() then
		M.open()
	else
		M.discover()
	end
end

--- Setup commands only (no heavy requires)
function M.setup()
	vim.api.nvim_create_user_command("DotnetTestRunner", function()
		M.toggle()
	end, { desc = "Toggle .NET test runner" })

	vim.api.nvim_create_user_command("DotnetTestRun", function()
		M.run_nearest()
	end, { desc = "Run nearest .NET test" })

	vim.api.nvim_create_user_command("DotnetTestDebug", function()
		M.debug_nearest()
	end, { desc = "Debug nearest .NET test" })

	vim.api.nvim_create_user_command("DotnetTestFocus", function()
		M.focus_nearest()
	end, { desc = "Open test runner focused on nearest test" })

	vim.api.nvim_create_user_command("DotnetTestDiscover", function()
		if not ui().is_open() then
			ui().open()
		end
		M.discover()
	end, { desc = "Discover .NET tests" })
end

return M
