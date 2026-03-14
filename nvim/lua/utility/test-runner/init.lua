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

--- Discovery state: tracks whether discovery is in progress and queued callbacks
local discovering = false
local discover_callbacks = {}

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

--- Find the test or theory node matching a method name.
--- If the method has a THEORY parent, returns the theory node instead.
---@param method_name string
---@return TestNode|nil
local function find_test_node(method_name)
	if not state().root_id then
		return nil
	end
	local match = nil
	for _, n in pairs(state().nodes) do
		if n.type == state().Type.TEST and n.fqn then
			local parsed = runner().parse_test_name(n.fqn)
			local base_method = parsed.method:match("^([^%(]+)")
			if base_method == method_name then
				match = n
				break
			end
		end
	end
	if not match then
		return nil
	end
	-- If this test belongs to a theory, return the theory node
	if match.parent_id then
		local parent = state().get(match.parent_id)
		if parent and parent.type == state().Type.THEORY then
			return parent
		end
	end
	return match
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

--- Ensure the runner UI is open
local function ensure_open()
	if not ui().is_open() then
		ui().open()
	end
end

--- Focus a node in the runner UI (expand parents, refresh, scroll to it)
---@param node TestNode
local function focus_in_ui(node)
	expand_parents(node)
	ensure_open()
	ui().refresh()
	ui().focus_node(node.id)
end

--- Check if discovery has completed (has TEST nodes, not just the root)
---@return boolean
local function has_tests()
	if not state().root_id then
		return false
	end
	for _, n in pairs(state().nodes) do
		if n.type == state().Type.TEST then
			return true
		end
	end
	return false
end

--- Start discovery from a solution file, calling all queued callbacks when done
---@param sln_file string  Full path to the .sln or .slnx file
local function do_discover(sln_file)
	local sln_dir = vim.fn.fnamemodify(sln_file, ":h")
	local root_name = vim.fn.fnamemodify(sln_file, ":t")
	state().sln_path = sln_dir
	state().sln_file = sln_file
	state().clear()

	state().register({
		id = "root:" .. sln_dir,
		display_name = root_name .. " (discovering...)",
		type = state().Type.SOLUTION,
		status = state().Status.DISCOVERING,
		expanded = true,
		parent_id = nil,
	})
	state().root_id = "root:" .. sln_dir
	ui().refresh()

	runner().discover(sln_file, root_name, function()
		discovering = false
		ui().refresh()
		local counts = state().counts()
		vim.notify(string.format("Found %d tests", counts.total), vim.log.levels.INFO)

		-- Flush all queued callbacks
		local cbs = discover_callbacks
		discover_callbacks = {}
		for _, cb in ipairs(cbs) do
			cb()
		end
	end)
end

--- Discover tests, queuing on_done for when discovery finishes.
--- If discovery is already in progress, just queues the callback.
---@param on_done? fun()
local function discover(on_done)
	if on_done then
		discover_callbacks[#discover_callbacks + 1] = on_done
	end

	-- Already running — callback is queued, nothing else to do
	if discovering then
		return
	end
	discovering = true
	vim.notify("Discovering tests...", vim.log.levels.INFO)

	local solutions = runner().find_solutions()

	if #solutions == 0 then
		discovering = false
		vim.notify("No solution file found", vim.log.levels.WARN)
		return
	end

	if #solutions == 1 then
		do_discover(solutions[1])
		return
	end

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
				do_discover(item.item)
			else
				discovering = false
			end
		end,
	})
end

--- Ensure tests are discovered, then run an action.
--- If tests exist, runs action immediately. Otherwise discovers first.
---@param on_done fun()
local function ensure_discovered(on_done)
	if has_tests() then
		on_done()
		return
	end
	if discovering then
		discover_callbacks[#discover_callbacks + 1] = on_done
		return
	end
	discover(on_done)
end

--- Open the test runner, discover tests if not yet done
function M.open()
	ensure_open()
	if not has_tests() and not discovering then
		discover()
	end
end

--- Toggle the test runner window
function M.toggle()
	if ui().is_open() then
		ui().close()
	else
		M.open()
	end
end

--- Discover tests (public, force re-discover)
function M.discover()
	ensure_open()
	-- Force: reset the flag so discovery runs even if one completed before
	discovering = false
	discover()
end

--- Run the test nearest to cursor in the current .cs buffer
function M.run_nearest()
	local method_name = find_method_at_cursor()
	if not method_name then
		return
	end

	ensure_discovered(function()
		local node = find_test_node(method_name)
		if node then
			focus_in_ui(node)
			runner().run(node)
		else
			vim.notify("Could not find test: " .. method_name, vim.log.levels.WARN)
		end
	end)
end

--- Debug the test nearest to cursor in the current .cs buffer
function M.debug_nearest()
	local method_name = find_method_at_cursor()
	if not method_name then
		return
	end

	ensure_discovered(function()
		local node = find_test_node(method_name)
		if node then
			ui().debug_test(node)
		else
			vim.notify("Could not find test: " .. method_name, vim.log.levels.WARN)
		end
	end)
end

--- Open the test runner with the nearest test focused/selected
function M.focus_nearest()
	local method_name = find_method_at_cursor()
	if not method_name then
		return
	end

	ensure_discovered(function()
		local node = find_test_node(method_name)
		if node then
			focus_in_ui(node)
		else
			vim.notify("Could not find test: " .. method_name, vim.log.levels.WARN)
		end
	end)
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
		M.discover()
	end, { desc = "Discover .NET tests" })
end

return M
