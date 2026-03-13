local state = require("utility.test-runner.state")
local runner = require("utility.test-runner.runner")

local M = {}

local ns = vim.api.nvim_create_namespace("dotnet_test_runner")

---@type snacks.win|nil
local main_win = nil

--- Icons per node type
local type_icons = {
	[state.Type.SOLUTION] = " ",
	[state.Type.PROJECT] = " ",
	[state.Type.NAMESPACE] = " ",
	[state.Type.CLASS] = " ",
	[state.Type.THEORY] = "󰇖 ",
	[state.Type.TEST] = "",
}

--- Status icons
local status_icons = {
	[state.Status.PASSED] = " ",
	[state.Status.FAILED] = " ",
	[state.Status.SKIPPED] = " ",
	[state.Status.RUNNING] = " ",
	[state.Status.BUILDING] = " ",
	[state.Status.DISCOVERING] = " ",
	[state.Status.IDLE] = "  ",
}

--- Highlight groups per status
local status_hl = {
	[state.Status.PASSED] = "DotnetTestPassed",
	[state.Status.FAILED] = "DotnetTestFailed",
	[state.Status.SKIPPED] = "DotnetTestSkipped",
	[state.Status.RUNNING] = "DotnetTestRunning",
	[state.Status.BUILDING] = "DotnetTestRunning",
	[state.Status.DISCOVERING] = "DotnetTestRunning",
	[state.Status.IDLE] = "DotnetTestIdle",
}

--- Highlight groups per node type
local type_hl = {
	[state.Type.SOLUTION] = "DotnetTestSolution",
	[state.Type.PROJECT] = "DotnetTestProject",
	[state.Type.NAMESPACE] = "DotnetTestNamespace",
	[state.Type.CLASS] = "DotnetTestClass",
	[state.Type.THEORY] = "DotnetTestTheory",
	[state.Type.TEST] = "Normal",
}

--- Setup highlight groups (links to standard groups for theme compatibility)
function M.setup_highlights()
	local hl = vim.api.nvim_set_hl
	hl(0, "DotnetTestPassed", { link = "DiagnosticOk" })
	hl(0, "DotnetTestFailed", { link = "DiagnosticError" })
	hl(0, "DotnetTestSkipped", { link = "DiagnosticWarn" })
	hl(0, "DotnetTestRunning", { link = "DiagnosticInfo" })
	hl(0, "DotnetTestIdle", { link = "Comment" })
	hl(0, "DotnetTestSolution", { link = "Directory" })
	hl(0, "DotnetTestProject", { link = "Type" })
	hl(0, "DotnetTestNamespace", { link = "Comment" })
	hl(0, "DotnetTestClass", { link = "Function" })
	hl(0, "DotnetTestTheory", { link = "Constant" })
	hl(0, "DotnetTestDuration", { link = "Comment" })
	hl(0, "DotnetTestHeader", { link = "Title" })
	hl(0, "DotnetTestHeaderCount", { link = "Comment" })
end

--- Spinner for loading states
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_idx = 1
local spinner_timer = nil

local function start_spinner()
	if spinner_timer then
		return
	end
	spinner_timer = vim.uv.new_timer()
	spinner_timer:start(
		0,
		80,
		vim.schedule_wrap(function()
			spinner_idx = (spinner_idx % #spinner_frames) + 1
			M.refresh()
		end)
	)
end

local function stop_spinner()
	if spinner_timer then
		spinner_timer:stop()
		spinner_timer:close()
		spinner_timer = nil
	end
end

--- Track which node is at each line for cursor-based operations
local line_to_node = {}

--- Render the test tree into the buffer
function M.refresh()
	if not main_win or not main_win:buf_valid() then
		return
	end

	local buf = main_win.buf
	local lines = {}
	local highlights = {} -- { line, col_start, col_end, hl_group }
	line_to_node = {}

	-- Header
	local counts = state.counts()
	local has_running = false
	for _, node in pairs(state.nodes) do
		if node.status == state.Status.RUNNING or node.status == state.Status.BUILDING or node.status == state.Status.DISCOVERING then
			has_running = true
			break
		end
	end

	local header_left
	if has_running then
		header_left = " " .. spinner_frames[spinner_idx] .. " Running..."
		start_spinner()
	else
		stop_spinner()
		if counts.failed > 0 then
			header_left = "  Tests"
		elseif counts.passed > 0 then
			header_left = "  Tests"
		else
			header_left = "  Tests"
		end
	end

	local header_right = ""
	if counts.total > 0 then
		local parts = {}
		if counts.passed > 0 then
			table.insert(parts, " " .. counts.passed)
		end
		if counts.failed > 0 then
			table.insert(parts, " " .. counts.failed)
		end
		if counts.skipped > 0 then
			table.insert(parts, " " .. counts.skipped)
		end
		header_right = table.concat(parts, "  ") .. "  (" .. counts.total .. ")"
	end

	table.insert(lines, header_left)
	table.insert(highlights, { 0, 0, #header_left, "DotnetTestHeader" })
	table.insert(lines, "")

	-- Tree
	local row = 2 -- 0-indexed, after header + blank line
	state.traverse_visible(function(node, depth)
		local indent = string.rep("  ", depth)
		local expand_icon = ""
		local has_children = #state.children(node.id) > 0
		if has_children then
			expand_icon = node.expanded and "▼ " or "▶ "
		else
			expand_icon = "  "
		end

		local icon = type_icons[node.type] or ""
		local status_icon = ""
		local duration_str = ""

		if node.type == state.Type.TEST then
			status_icon = status_icons[node.status] or "  "
			if node.duration then
				duration_str = "  " .. node.duration
			end
		else
			if node.status ~= state.Status.IDLE then
				status_icon = status_icons[node.status] or ""
			end
		end

		local line = indent .. expand_icon .. icon .. status_icon .. node.display_name .. duration_str
		table.insert(lines, line)

		local icon_start = #indent + #expand_icon + #icon
		if status_icon ~= "" and status_icon ~= "  " then
			local hl_group = status_hl[node.status]
			if hl_group then
				table.insert(highlights, { row, icon_start, icon_start + #status_icon + #node.display_name, hl_group })
			end
		else
			local hl_group = type_hl[node.type]
			if hl_group then
				table.insert(highlights, { row, icon_start, icon_start + #status_icon + #node.display_name, hl_group })
			end
		end

		if duration_str ~= "" then
			local dur_start = #line - #duration_str
			table.insert(highlights, { row, dur_start, #line, "DotnetTestDuration" })
		end

		-- Show inline error preview for failed tests
		if node.type == state.Type.TEST and node.status == state.Status.FAILED and node.error_message then
			local err_line = node.error_message:match("^([^\n]+)")
			if err_line then
				row = row + 1
				local err_display = indent .. "    " .. err_line
				if #err_display > 100 then
					err_display = err_display:sub(1, 97) .. "..."
				end
				table.insert(lines, err_display)
				table.insert(highlights, { row, 0, #err_display, "DiagnosticError" })
			end
		end

		line_to_node[row] = node
		row = row + 1
	end)

	-- Footer hint
	table.insert(lines, "")
	local legend = " ?: keymaps"
	table.insert(lines, legend)
	table.insert(highlights, { row + 1, 0, #legend, "Comment" })

	-- Write to buffer
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	-- Apply highlights
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(buf, ns, hl[4], hl[1], hl[2], hl[3])
	end

	-- Header right (right-aligned)
	if header_right ~= "" and main_win:win_valid() then
		local win_width = vim.api.nvim_win_get_width(main_win.win)
		local padding = win_width - vim.fn.strdisplaywidth(header_left) - vim.fn.strdisplaywidth(header_right) - 3
		if padding > 0 then
			vim.bo[buf].modifiable = true
			local full_header = header_left .. string.rep(" ", padding) .. header_right
			vim.api.nvim_buf_set_lines(buf, 0, 1, false, { full_header })
			vim.bo[buf].modifiable = false
			vim.api.nvim_buf_add_highlight(buf, ns, "DotnetTestHeader", 0, 0, #header_left)
			vim.api.nvim_buf_add_highlight(buf, ns, "DotnetTestHeaderCount", 0, #header_left, #full_header)
		end
	end
end

--- Move cursor to a specific node by id
---@param node_id string
function M.focus_node(node_id)
	if not main_win or not main_win:win_valid() then
		return
	end
	for row, node in pairs(line_to_node) do
		if node.id == node_id then
			vim.api.nvim_win_set_cursor(main_win.win, { row + 1, 0 })
			return
		end
	end
end

--- Get the node under the cursor
---@return TestNode|nil
function M.node_at_cursor()
	if not main_win or not main_win:win_valid() then
		return nil
	end
	local row = vim.api.nvim_win_get_cursor(main_win.win)[1] - 1
	return line_to_node[row]
end

--- Open error/result details in a Snacks float
---@param node TestNode
function M.peek_results(node)
	if not node.error_message and not node.stack_trace and not node.stdout then
		if node.status == state.Status.PASSED then
			vim.notify("Test passed - no error details", vim.log.levels.INFO)
		else
			vim.notify("No results available for this test", vim.log.levels.INFO)
		end
		return
	end

	local lines = {}
	local highlights = {}

	table.insert(lines, " " .. node.display_name)
	table.insert(highlights, { 0, status_hl[node.status] or "Normal" })
	table.insert(lines, "")

	if node.error_message then
		table.insert(lines, "Error:")
		table.insert(highlights, { #lines - 1, "DiagnosticError" })
		for line in node.error_message:gmatch("[^\n]+") do
			table.insert(lines, "  " .. line)
			table.insert(highlights, { #lines - 1, "Normal" })
		end
		table.insert(lines, "")
	end

	if node.stack_trace then
		table.insert(lines, "Stack Trace:")
		table.insert(highlights, { #lines - 1, "Title" })
		for line in node.stack_trace:gmatch("[^\n]+") do
			table.insert(lines, "  " .. line)
			local file = line:match("in (.+):line %d+")
			if file and not file:match("^%s*at System%.") and not file:match("^%s*at Microsoft%.") then
				table.insert(highlights, { #lines - 1, "String" })
			else
				table.insert(highlights, { #lines - 1, "Comment" })
			end
		end
		table.insert(lines, "")
	end

	if node.stdout then
		table.insert(lines, "Output:")
		table.insert(highlights, { #lines - 1, "DiagnosticWarn" })
		for line in node.stdout:gmatch("[^\n]+") do
			table.insert(lines, "  " .. line)
			table.insert(highlights, { #lines - 1, "Normal" })
		end
	end

	local peek_win = Snacks.win({
		position = "float",
		width = 0.6,
		height = 0.5,
		border = "rounded",
		title = " Test Results ",
		title_pos = "center",
		enter = true,
		text = lines,
		bo = { modifiable = false, filetype = "dotnet-test-results" },
		keys = {
			q = "close",
			["<Esc>"] = "close",
			gf = {
				function(self)
					local cursor_line = self:line(vim.api.nvim_win_get_cursor(self.win)[1])
					local file, lnum = cursor_line:match("in (.+):line (%d+)")
					if file and vim.fn.filereadable(file) == 1 then
						self:close()
						vim.cmd("edit " .. vim.fn.fnameescape(file))
						vim.api.nvim_win_set_cursor(0, { tonumber(lnum) or 1, 0 })
					end
				end,
				desc = "Go to stack frame",
			},
		},
		on_buf = function(self)
			local peek_ns = vim.api.nvim_create_namespace("dotnet_test_results")
			for _, hl in ipairs(highlights) do
				vim.api.nvim_buf_add_highlight(self.buf, peek_ns, hl[2], hl[1], 0, -1)
			end
		end,
	})
end

--- Navigate to source file for a test node
---@param node TestNode
function M.goto_source(node)
	if not node.fqn then
		vim.notify("No source location for this node", vim.log.levels.INFO)
		return
	end

	local parsed = runner.parse_test_name(node.fqn)
	local method_name = parsed.method:match("^([^%(]+)")

	local cwd = vim.fn.getcwd()
	local cs_files = vim.fn.globpath(cwd, "**/*.cs", false, true)

	for _, file in ipairs(cs_files) do
		if not file:match("/bin/") and not file:match("/obj/") then
			local file_lines = vim.fn.readfile(file)
			for i, line in ipairs(file_lines) do
				if line:match("%s+" .. vim.pesc(method_name) .. "%s*%(") or line:match("%s+" .. vim.pesc(method_name) .. "%(") then
					M.close()
					vim.cmd("edit " .. vim.fn.fnameescape(file))
					vim.api.nvim_win_set_cursor(0, { i, 0 })
					vim.cmd("normal! zz")
					return
				end
			end
		end
	end

	vim.notify("Could not find source for " .. method_name, vim.log.levels.WARN)
end

--- Debug a single test using DAP
--- Launches the test DLL directly under the debugger (requires OutputType=Exe test projects)
---@param node TestNode
function M.debug_test(node)
	if node.type ~= state.Type.TEST then
		vim.notify("Debug is only supported for individual tests", vim.log.levels.WARN)
		return
	end

	local project_path = runner.get_project_path(node)
	if not project_path then
		vim.notify("Could not determine project for test", vim.log.levels.ERROR)
		return
	end

	local fqn = node.fqn
	if not fqn then
		vim.notify("No fully qualified name for test", vim.log.levels.ERROR)
		return
	end

	-- Strip params for method filter (e.g. "Ns.Class.Method(args)" -> "Ns.Class.Method")
	local filter_name = fqn:match("^(.-)%(") or fqn
	local project_name = vim.fn.fnamemodify(project_path, ":t:r")
	local project_dir = vim.fn.fnamemodify(project_path, ":h")

	-- Close the test runner so DAP UI has space
	M.close()

	vim.notify("Building " .. project_name .. " for debug...", vim.log.levels.INFO)

	vim.system(
		{ "dotnet", "build", "-c", "Debug", project_path },
		{ text = true },
		vim.schedule_wrap(function(build_result)
			if build_result.code ~= 0 then
				vim.notify("Build failed:\n" .. (build_result.stderr or build_result.stdout or ""), vim.log.levels.ERROR)
				return
			end

			-- Find the test DLL in the build output
			local dlls = vim.fn.glob(project_dir .. "/bin/Debug/**/" .. project_name .. ".dll", false, true)
			if #dlls == 0 then
				vim.notify("Could not find debug DLL for " .. project_name, vim.log.levels.ERROR)
				return
			end

			local dll_path = dlls[1]
			local dap = require("dap")

			-- Launch the test DLL directly under the debugger.
			-- This works for test projects with OutputType=Exe (xUnit v3, Microsoft.Testing.Platform).
			-- The test runner is in-process, so breakpoints in test code work without attach.
			dap.run({
				type = "coreclr",
				name = "Debug Test: " .. node.display_name,
				request = "launch",
				program = dll_path,
				args = { "-method", filter_name .. "*" },
				cwd = project_dir,
				stopAtEntry = false,
			})
		end)
	)
end

--- Show help float with available keymaps
function M.show_help()
	local keymaps = {
		{ "o", "Toggle expand/collapse" },
		{ "O", "Expand all under cursor" },
		{ "W", "Collapse all under cursor" },
		{ "r", "Run test/class/project under cursor" },
		{ "R", "Run all tests" },
		{ "d", "Debug test under cursor" },
		{ "p", "Peek error details / stack trace" },
		{ "gf", "Go to source file" },
		{ "D", "Re-discover tests" },
		{ "<C-c>", "Cancel active test run" },
		{ "?", "Show this help" },
		{ "q", "Close test runner" },
	}

	local lines = {}
	for _, km in ipairs(keymaps) do
		table.insert(lines, "  " .. km[1] .. string.rep(" ", 10 - #km[1]) .. km[2])
	end

	Snacks.win({
		position = "float",
		width = 44,
		height = #lines,
		border = "rounded",
		title = " Keymaps ",
		title_pos = "center",
		enter = true,
		text = lines,
		bo = { modifiable = false },
		keys = {
			q = "close",
			["<Esc>"] = "close",
			["?"] = "close",
		},
		on_buf = function(self)
			local help_ns = vim.api.nvim_create_namespace("dotnet_test_help")
			for i = 0, #lines - 1 do
				vim.api.nvim_buf_add_highlight(self.buf, help_ns, "Special", i, 0, 12)
			end
		end,
	})
end

--- Create or show the test runner as a Snacks floating window
function M.open()
	if main_win and main_win:win_valid() then
		main_win:focus()
		return
	end

	main_win = Snacks.win({
		position = "float",
		width = 0.5,
		height = 0.7,
		border = "rounded",
		title = " Test Runner ",
		title_pos = "center",
		enter = true,
		minimal = true,
		bo = {
			buftype = "nofile",
			filetype = "dotnet-test-runner",
			modifiable = false,
		},
		wo = {
			cursorline = true,
			wrap = false,
		},
		-- Disable default q=close so we control it
		keys = {},
		on_close = function()
			stop_spinner()
			main_win = nil
		end,
		on_buf = function(self)
			local buf = self.buf
			local opts = { buffer = buf, nowait = true }

			vim.keymap.set("n", "o", function()
				local node = M.node_at_cursor()
				if node then
					node.expanded = not node.expanded
					M.refresh()
				end
			end, opts)

			vim.keymap.set("n", "O", function()
				local node = M.node_at_cursor()
				if node then
					state.expand_all(node.id)
					M.refresh()
				end
			end, opts)

			vim.keymap.set("n", "W", function()
				local node = M.node_at_cursor()
				if node then
					state.collapse_all(node.id)
					M.refresh()
				end
			end, opts)

			vim.keymap.set("n", "r", function()
				local node = M.node_at_cursor()
				if node then
					node.expanded = true
					runner.run(node)
				end
			end, opts)

			vim.keymap.set("n", "R", function()
				if state.root_id then
					local root = state.get(state.root_id)
					if root then
						runner.run(root)
					end
				end
			end, opts)

			vim.keymap.set("n", "d", function()
				local node = M.node_at_cursor()
				if node then
					M.debug_test(node)
				end
			end, opts)

			vim.keymap.set("n", "p", function()
				local node = M.node_at_cursor()
				if node then
					M.peek_results(node)
				end
			end, opts)

			vim.keymap.set("n", "gf", function()
				local node = M.node_at_cursor()
				if node then
					M.goto_source(node)
				end
			end, opts)

			vim.keymap.set("n", "<C-c>", function()
				state.cancel()
				vim.notify("Test run cancelled", vim.log.levels.INFO)
			end, opts)

			vim.keymap.set("n", "D", function()
				if state.sln_path then
					local root_name = vim.fn.fnamemodify(state.sln_path, ":t")
					runner.discover(state.sln_path, root_name, function()
						M.refresh()
					end)
				end
			end, opts)

			vim.keymap.set("n", "?", function()
				M.show_help()
			end, opts)

			vim.keymap.set("n", "q", function()
				M.close()
			end, opts)

			vim.keymap.set("n", "<Esc>", function()
				M.close()
			end, opts)
		end,
	})

	-- Hook up state changes to refresh
	state.on_update = function()
		vim.schedule(function()
			M.refresh()
		end)
	end

	M.refresh()
end

--- Close the test runner window
function M.close()
	stop_spinner()
	if main_win and main_win:valid() then
		main_win:close()
	end
	main_win = nil
end

--- Toggle the test runner window
function M.toggle()
	if main_win and main_win:win_valid() then
		M.close()
	else
		M.open()
	end
end

--- Check if the test runner window is open
function M.is_open()
	return main_win and main_win:win_valid()
end

return M
