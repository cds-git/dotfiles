local state = require("utility.test-runner.state")
local runner = require("utility.test-runner.runner")

local M = {}

local ns = vim.api.nvim_create_namespace("dotnet_test_runner")
local buf = nil
local win = nil

--- Icons per node type
local type_icons = {
	[state.Type.SOLUTION] = " ",
	[state.Type.PROJECT] = " ",
	[state.Type.NAMESPACE] = " ",
	[state.Type.CLASS] = " ",
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
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

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
			-- For container nodes, show aggregated status icon
			if node.status ~= state.Status.IDLE then
				status_icon = status_icons[node.status] or ""
			end
		end

		local line = indent .. expand_icon .. icon .. status_icon .. node.display_name .. duration_str
		table.insert(lines, line)

		-- Highlight the status icon
		local icon_start = #indent + #expand_icon + #icon
		if status_icon ~= "" and status_icon ~= "  " then
			local hl = status_hl[node.status]
			if hl then
				table.insert(highlights, { row, icon_start, icon_start + #status_icon + #node.display_name, hl })
			end
		else
			-- Highlight by type
			local hl = type_hl[node.type]
			if hl then
				table.insert(highlights, { row, icon_start, icon_start + #status_icon + #node.display_name, hl })
			end
		end

		-- Duration in comment color
		if duration_str ~= "" then
			local dur_start = #line - #duration_str
			table.insert(highlights, { row, dur_start, #line, "DotnetTestDuration" })
		end

		line_to_node[row] = node
		row = row + 1
	end)

	-- Footer
	table.insert(lines, "")
	local legend = " r: run  R: run all  p: peek  gf: goto  o: toggle  q: close"
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
	if header_right ~= "" and win and vim.api.nvim_win_is_valid(win) then
		local win_width = vim.api.nvim_win_get_width(win)
		local padding = win_width - vim.fn.strdisplaywidth(header_left) - vim.fn.strdisplaywidth(header_right) - 1
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

--- Get the node under the cursor
---@return TestNode|nil
function M.node_at_cursor()
	if not win or not vim.api.nvim_win_is_valid(win) then
		return nil
	end
	local row = vim.api.nvim_win_get_cursor(win)[1] - 1 -- 0-indexed
	return line_to_node[row]
end

--- Open error/result details in a floating window
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
		local frame_map = {}
		for line in node.stack_trace:gmatch("[^\n]+") do
			table.insert(lines, "  " .. line)
			-- Highlight user code vs framework code
			local file, lnum = line:match("in (.+):line (%d+)")
			if file and not file:match("^%s*at System%.") and not file:match("^%s*at Microsoft%.") then
				table.insert(highlights, { #lines - 1, "String" })
				frame_map[#lines - 1] = { file = file, line = tonumber(lnum) }
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

	-- Create float
	local float_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
	vim.bo[float_buf].modifiable = false
	vim.bo[float_buf].bufhidden = "wipe"
	vim.bo[float_buf].filetype = "dotnet-test-results"

	local width = math.min(100, vim.o.columns - 10)
	local height = math.min(#lines + 1, vim.o.lines - 6)
	local float_win = vim.api.nvim_open_win(float_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Test Results ",
		title_pos = "center",
	})

	-- Apply highlights
	local float_ns = vim.api.nvim_create_namespace("dotnet_test_results")
	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(float_buf, float_ns, hl[2], hl[1], 0, -1)
	end

	-- Keymaps for the float
	local function close_float()
		if vim.api.nvim_win_is_valid(float_win) then
			vim.api.nvim_win_close(float_win, true)
		end
	end

	vim.keymap.set("n", "q", close_float, { buffer = float_buf, nowait = true })
	vim.keymap.set("n", "<Esc>", close_float, { buffer = float_buf, nowait = true })

	-- gf to jump to stack frame under cursor
	vim.keymap.set("n", "gf", function()
		local cursor_row = vim.api.nvim_win_get_cursor(float_win)[1] - 1
		-- Parse the line for a file:line pattern
		local cursor_line = vim.api.nvim_buf_get_lines(float_buf, cursor_row, cursor_row + 1, false)[1] or ""
		local file, lnum = cursor_line:match("in (.+):line (%d+)")
		if file and vim.fn.filereadable(file) == 1 then
			close_float()
			vim.cmd("edit " .. vim.fn.fnameescape(file))
			vim.api.nvim_win_set_cursor(0, { tonumber(lnum) or 1, 0 })
		end
	end, { buffer = float_buf, nowait = true })
end

--- Navigate to source file for a test node
---@param node TestNode
function M.goto_source(node)
	if not node.fqn then
		vim.notify("No source location for this node", vim.log.levels.INFO)
		return
	end

	-- Parse the FQN to get class and method
	local parsed = runner.parse_test_name(node.fqn)
	local method_name = parsed.method:match("^([^%(]+)") -- strip params

	-- Search for the method in .cs files
	local cwd = vim.fn.getcwd()
	local cs_files = vim.fn.globpath(cwd, "**/*.cs", false, true)

	for _, file in ipairs(cs_files) do
		-- Skip bin/obj
		if not file:match("/bin/") and not file:match("/obj/") then
			local file_lines = vim.fn.readfile(file)
			for i, line in ipairs(file_lines) do
				-- Match method declaration patterns
				if line:match("%s+" .. vim.pesc(method_name) .. "%s*%(") or line:match("%s+" .. vim.pesc(method_name) .. "%(") then
					-- Focus main editor window before opening
					for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
						local w_buf = vim.api.nvim_win_get_buf(w)
						if vim.bo[w_buf].filetype ~= "dotnet-test-runner" then
							vim.api.nvim_set_current_win(w)
							break
						end
					end
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

--- Setup keymaps on the test runner buffer
local function setup_keymaps()
	local opts = { buffer = buf, nowait = true }

	-- Toggle expand/collapse
	vim.keymap.set("n", "o", function()
		local node = M.node_at_cursor()
		if node then
			node.expanded = not node.expanded
			M.refresh()
		end
	end, opts)

	-- Expand all under cursor
	vim.keymap.set("n", "O", function()
		local node = M.node_at_cursor()
		if node then
			state.expand_all(node.id)
			M.refresh()
		end
	end, opts)

	-- Collapse all under cursor
	vim.keymap.set("n", "W", function()
		local node = M.node_at_cursor()
		if node then
			state.collapse_all(node.id)
			M.refresh()
		end
	end, opts)

	-- Run tests for node under cursor
	vim.keymap.set("n", "r", function()
		local node = M.node_at_cursor()
		if node then
			-- Expand so we can see results
			node.expanded = true
			runner.run(node)
		end
	end, opts)

	-- Run all tests
	vim.keymap.set("n", "R", function()
		if state.root_id then
			local root = state.get(state.root_id)
			if root then
				runner.run(root)
			end
		end
	end, opts)

	-- Peek results
	vim.keymap.set("n", "p", function()
		local node = M.node_at_cursor()
		if node then
			M.peek_results(node)
		end
	end, opts)

	-- Go to source
	vim.keymap.set("n", "gf", function()
		local node = M.node_at_cursor()
		if node then
			M.goto_source(node)
		end
	end, opts)

	-- Cancel active run
	vim.keymap.set("n", "<C-c>", function()
		state.cancel()
		vim.notify("Test run cancelled", vim.log.levels.INFO)
	end, opts)

	-- Re-discover
	vim.keymap.set("n", "D", function()
		if state.sln_path then
			runner.discover(state.sln_path, function()
				M.refresh()
			end)
		end
	end, opts)

	-- Close
	vim.keymap.set("n", "q", function()
		M.close()
	end, opts)
	vim.keymap.set("n", "<Esc>", function()
		M.close()
	end, opts)
end

--- Create or show the test runner buffer in a vsplit
function M.open()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return
	end

	-- Create buffer if needed
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		buf = vim.api.nvim_create_buf(false, true)
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "hide"
		vim.bo[buf].swapfile = false
		vim.bo[buf].filetype = "dotnet-test-runner"
		vim.api.nvim_buf_set_name(buf, "dotnet-test-runner")
		setup_keymaps()
	end

	-- Open in vsplit on the right
	vim.cmd("botright vsplit")
	win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_win_set_width(win, 60)

	-- Window options
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].wrap = false
	vim.wo[win].cursorline = true
	vim.wo[win].winfixwidth = true

	-- Hook up state changes to refresh
	state.on_update = function()
		vim.schedule(function()
			M.refresh()
		end)
	end

	-- Auto-close cleanup
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			win = nil
			stop_spinner()
		end,
	})

	M.refresh()
end

--- Close the test runner window
function M.close()
	stop_spinner()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
		win = nil
	end
end

--- Toggle the test runner window
function M.toggle()
	if win and vim.api.nvim_win_is_valid(win) then
		M.close()
	else
		M.open()
	end
end

--- Check if the test runner window is open
function M.is_open()
	return win and vim.api.nvim_win_is_valid(win)
end

return M
