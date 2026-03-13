local state = require("utility.test-runner.state")
local runner = require("utility.test-runner.runner")

local M = {}

local ns = vim.api.nvim_create_namespace("dotnet_test_runner")
---@type snacks.win|nil
local main_win = nil
local line_to_node = {}

-- Spinner
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_idx = 1
local spinner_timer = nil

local function spinner_char()
	return spinner_frames[spinner_idx]
end

local function start_spinner()
	if spinner_timer then
		return
	end
	spinner_timer = vim.uv.new_timer()
	spinner_timer:start(0, 80, vim.schedule_wrap(function()
		spinner_idx = (spinner_idx % #spinner_frames) + 1
		M.refresh()
	end))
end

local function stop_spinner()
	if spinner_timer then
		spinner_timer:stop()
		spinner_timer:close()
		spinner_timer = nil
	end
end

-- Display config tables
local type_icons = {
	[state.Type.SOLUTION] = " ",
	[state.Type.PROJECT] = " ",
	[state.Type.NAMESPACE] = " ",
	[state.Type.CLASS] = " ",
	[state.Type.THEORY] = "󰇖 ",
	[state.Type.TEST] = "",
}

local type_hl = {
	[state.Type.SOLUTION] = "DotnetTestSolution",
	[state.Type.PROJECT] = "DotnetTestProject",
	[state.Type.NAMESPACE] = "DotnetTestNamespace",
	[state.Type.CLASS] = "DotnetTestClass",
	[state.Type.THEORY] = "DotnetTestTheory",
	[state.Type.TEST] = "Normal",
}

local status_hl = {
	[state.Status.PASSED] = "DotnetTestPassed",
	[state.Status.FAILED] = "DotnetTestFailed",
	[state.Status.SKIPPED] = "DotnetTestSkipped",
	[state.Status.RUNNING] = "DotnetTestRunning",
	[state.Status.BUILDING] = "DotnetTestRunning",
	[state.Status.DISCOVERING] = "DotnetTestRunning",
	[state.Status.IDLE] = "DotnetTestIdle",
}

local status_icons = {
	[state.Status.PASSED] = " ",
	[state.Status.FAILED] = " ",
	[state.Status.SKIPPED] = " ",
	[state.Status.BUILDING] = " ",
	[state.Status.DISCOVERING] = " ",
	[state.Status.IDLE] = "  ",
}

function M.setup_highlights()
	local links = {
		DotnetTestPassed = "DiagnosticOk",
		DotnetTestFailed = "DiagnosticError",
		DotnetTestSkipped = "DiagnosticWarn",
		DotnetTestRunning = "DiagnosticInfo",
		DotnetTestIdle = "Comment",
		DotnetTestSolution = "Directory",
		DotnetTestProject = "Type",
		DotnetTestNamespace = "Comment",
		DotnetTestClass = "Function",
		DotnetTestTheory = "Constant",
		DotnetTestDuration = "Comment",
		DotnetTestHeader = "Title",
		DotnetTestHeaderCount = "Comment",
	}
	for name, target in pairs(links) do
		vim.api.nvim_set_hl(0, name, { link = target })
	end
end

--- Get the status icon for a node, with animated spinner for running states
---@param node TestNode
---@return string icon, string|nil hl_group
local function node_status_icon(node)
	local is_running = node.status == state.Status.RUNNING
		or node.status == state.Status.BUILDING
		or node.status == state.Status.DISCOVERING

	if is_running then
		return spinner_char() .. " ", status_hl[node.status]
	end

	if node.type == state.Type.TEST then
		return status_icons[node.status] or "  ", status_hl[node.status]
	end

	if node.status ~= state.Status.IDLE then
		return status_icons[node.status] or "", status_hl[node.status]
	end

	return "", nil
end

--- Build header lines and their highlights
---@param has_running boolean
---@return string left, string right
local function build_header(has_running)
	local counts = state.counts()

	local left
	if has_running then
		left = " " .. spinner_char() .. " Running..."
	elseif counts.failed > 0 then
		left = "  Tests"
	elseif counts.passed > 0 then
		left = "  Tests"
	else
		left = "  Tests"
	end

	local right = ""
	if counts.total > 0 then
		local parts = {}
		if counts.passed > 0 then
			parts[#parts + 1] = " " .. counts.passed
		end
		if counts.failed > 0 then
			parts[#parts + 1] = " " .. counts.failed
		end
		if counts.skipped > 0 then
			parts[#parts + 1] = " " .. counts.skipped
		end
		right = table.concat(parts, "  ") .. "  (" .. counts.total .. ")"
	end

	return left, right
end

function M.refresh()
	if not main_win or not main_win:buf_valid() then
		return
	end

	local buf = main_win.buf
	local lines, hls = {}, {}
	line_to_node = {}

	-- Check for running state
	local has_running = false
	for _, node in pairs(state.nodes) do
		if node.status == state.Status.RUNNING or node.status == state.Status.BUILDING or node.status == state.Status.DISCOVERING then
			has_running = true
			break
		end
	end

	if has_running then
		start_spinner()
	else
		stop_spinner()
	end

	-- Header
	local header_left, header_right = build_header(has_running)
	lines[1] = header_left
	hls[#hls + 1] = { 0, 0, #header_left, "DotnetTestHeader" }
	lines[2] = ""

	-- Tree
	local row = 2
	state.traverse_visible(function(node, depth)
		local indent = string.rep("  ", depth)
		local has_children = #state.children(node.id) > 0
		local expand = has_children and (node.expanded and "▼ " or "▶ ") or "  "
		local icon = type_icons[node.type] or ""
		local status_icon, shl = node_status_icon(node)
		local duration = (node.type == state.Type.TEST and node.duration) and ("  " .. node.duration) or ""

		local line = indent .. expand .. icon .. status_icon .. node.display_name .. duration
		lines[#lines + 1] = line

		-- Highlight: status color takes priority, else type color
		local hl_start = #indent + #expand + #icon
		local hl_end = hl_start + #status_icon + #node.display_name
		local hl_group = (shl and status_icon ~= "  ") and shl or type_hl[node.type]
		if hl_group then
			hls[#hls + 1] = { row, hl_start, hl_end, hl_group }
		end

		if duration ~= "" then
			hls[#hls + 1] = { row, #line - #duration, #line, "DotnetTestDuration" }
		end

		-- Inline error preview for failed tests
		if node.type == state.Type.TEST and node.status == state.Status.FAILED and node.error_message then
			local err_line = node.error_message:match("^([^\n]+)")
			if err_line then
				row = row + 1
				local err = indent .. "    " .. err_line
				if #err > 100 then
					err = err:sub(1, 97) .. "..."
				end
				lines[#lines + 1] = err
				hls[#hls + 1] = { row, 0, #err, "DiagnosticError" }
			end
		end

		line_to_node[row] = node
		row = row + 1
	end)

	-- Footer
	lines[#lines + 1] = ""
	local legend = " ?: keymaps"
	lines[#lines + 1] = legend
	hls[#hls + 1] = { row + 1, 0, #legend, "Comment" }

	-- Write buffer
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	-- Highlights
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, hl in ipairs(hls) do
		vim.api.nvim_buf_add_highlight(buf, ns, hl[4], hl[1], hl[2], hl[3])
	end

	-- Right-aligned header counts
	if header_right ~= "" and main_win:win_valid() then
		local win_w = vim.api.nvim_win_get_width(main_win.win)
		local pad = win_w - vim.fn.strdisplaywidth(header_left) - vim.fn.strdisplaywidth(header_right) - 3
		if pad > 0 then
			vim.bo[buf].modifiable = true
			local full = header_left .. string.rep(" ", pad) .. header_right
			vim.api.nvim_buf_set_lines(buf, 0, 1, false, { full })
			vim.bo[buf].modifiable = false
			vim.api.nvim_buf_add_highlight(buf, ns, "DotnetTestHeader", 0, 0, #header_left)
			vim.api.nvim_buf_add_highlight(buf, ns, "DotnetTestHeaderCount", 0, #header_left, #full)
		end
	end
end

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

---@return TestNode|nil
function M.node_at_cursor()
	if not main_win or not main_win:win_valid() then
		return nil
	end
	return line_to_node[vim.api.nvim_win_get_cursor(main_win.win)[1] - 1]
end

--- Perform an action on the node at cursor
---@param fn fun(node: TestNode)
local function with_cursor_node(fn)
	local node = M.node_at_cursor()
	if node then
		fn(node)
	end
end

---@param node TestNode
function M.peek_results(node)
	if not node.error_message and not node.stack_trace and not node.stdout then
		vim.notify(node.status == state.Status.PASSED and "Test passed" or "No results available", vim.log.levels.INFO)
		return
	end

	local lines, hls = {}, {}

	local function add(text, hl)
		lines[#lines + 1] = text
		hls[#hls + 1] = { #lines - 1, hl }
	end

	local function add_block(header, header_hl, content, line_hl_fn)
		add(header, header_hl)
		for line in content:gmatch("[^\n]+") do
			add("  " .. line, line_hl_fn and line_hl_fn(line) or "Normal")
		end
		add("", "Normal")
	end

	add(" " .. node.display_name, status_hl[node.status] or "Normal")
	add("", "Normal")

	if node.error_message then
		add_block("Error:", "DiagnosticError", node.error_message)
	end

	if node.stack_trace then
		add_block("Stack Trace:", "Title", node.stack_trace, function(line)
			local file = line:match("in (.+):line %d+")
			return (file and not file:match("^%s*at System%.") and not file:match("^%s*at Microsoft%.")) and "String" or "Comment"
		end)
	end

	if node.stdout then
		add_block("Output:", "DiagnosticWarn", node.stdout)
	end

	Snacks.win({
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
			for _, hl in ipairs(hls) do
				vim.api.nvim_buf_add_highlight(self.buf, peek_ns, hl[2], hl[1], 0, -1)
			end
		end,
	})
end

---@param node TestNode
function M.goto_source(node)
	if not node.fqn then
		vim.notify("No source location for this node", vim.log.levels.INFO)
		return
	end

	local method_name = runner.parse_test_name(node.fqn).method:match("^([^%(]+)")
	local pattern = vim.pesc(method_name)

	for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), "**/*.cs", false, true)) do
		if not file:match("/bin/") and not file:match("/obj/") then
			for i, line in ipairs(vim.fn.readfile(file)) do
				if line:match("%s+" .. pattern .. "%s*%(") or line:match("%s+" .. pattern .. "%(") then
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

---@param node TestNode
function M.debug_test(node)
	if node.type ~= state.Type.TEST and node.type ~= state.Type.THEORY then
		vim.notify("Debug is only supported for tests and theories", vim.log.levels.WARN)
		return
	end

	-- xUnit v3 -method can only filter by method name, not individual theory cases.
	-- Escalate theory cases to their parent theory (runs all cases for that method).
	local target = node
	if node.type == state.Type.TEST and node.parent_id then
		local parent = state.get(node.parent_id)
		if parent and parent.type == state.Type.THEORY then
			target = parent
			vim.notify("Debugging all cases of " .. parent.display_name .. " (xUnit cannot target single theory cases)", vim.log.levels.INFO)
		end
	end

	local fqn, project_path
	if target.type == state.Type.THEORY then
		local children = state.children(target.id)
		if #children == 0 then
			vim.notify("Theory has no test cases", vim.log.levels.WARN)
			return
		end
		fqn = children[1].fqn
		project_path = runner.get_project_path(children[1])
	else
		fqn = target.fqn
		project_path = runner.get_project_path(target)
	end

	if not project_path or not fqn then
		vim.notify("Could not determine project or test name", vim.log.levels.ERROR)
		return
	end

	-- xUnit v3 -method matches on fully qualified method name (no params)
	-- Strip params if present, use exact match for standalone tests
	local method_filter = fqn:match("^(.-)%(") or fqn

	local project_name = vim.fn.fnamemodify(project_path, ":t:r")
	local project_dir = vim.fn.fnamemodify(project_path, ":h")

	M.close()
	vim.notify("Building " .. project_name .. " for debug...", vim.log.levels.INFO)

	vim.system({ "dotnet", "build", "-c", "Debug", project_path }, { text = true }, vim.schedule_wrap(function(result)
		if result.code ~= 0 then
			vim.notify("Build failed:\n" .. (result.stderr or result.stdout or ""), vim.log.levels.ERROR)
			return
		end

		local dlls = vim.fn.glob(project_dir .. "/bin/Debug/**/" .. project_name .. ".dll", false, true)
		if #dlls == 0 then
			vim.notify("Could not find debug DLL for " .. project_name, vim.log.levels.ERROR)
			return
		end

		require("dap").run({
			type = "coreclr",
			name = "Debug Test: " .. node.display_name,
			request = "launch",
			program = dlls[1],
			args = { "-method", method_filter },
			cwd = project_dir,
			stopAtEntry = false,
		})
	end))
end

function M.show_help()
	local keymaps = {
		{ "o", "Toggle expand/collapse" },
		{ "O", "Expand all under cursor" },
		{ "W", "Collapse all under cursor" },
		{ "r", "Run test/class/project" },
		{ "R", "Run all tests" },
		{ "d", "Debug test under cursor" },
		{ "p", "Peek error / stack trace" },
		{ "gf", "Go to source file" },
		{ "D", "Re-discover tests" },
		{ "<C-c>", "Cancel active run" },
		{ "?", "Show this help" },
		{ "q", "Close" },
	}

	local lines = {}
	for _, km in ipairs(keymaps) do
		lines[#lines + 1] = "  " .. km[1] .. string.rep(" ", 10 - #km[1]) .. km[2]
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
		keys = { q = "close", ["<Esc>"] = "close", ["?"] = "close" },
		on_buf = function(self)
			local help_ns = vim.api.nvim_create_namespace("dotnet_test_help")
			for i = 0, #lines - 1 do
				vim.api.nvim_buf_add_highlight(self.buf, help_ns, "Special", i, 0, 12)
			end
		end,
	})
end

-- Buffer keymaps as a declarative table
local keymap_defs = {
	o = function()
		with_cursor_node(function(n)
			n.expanded = not n.expanded
			M.refresh()
		end)
	end,
	O = function()
		with_cursor_node(function(n)
			state.expand_all(n.id)
			M.refresh()
		end)
	end,
	W = function()
		with_cursor_node(function(n)
			state.collapse_all(n.id)
			M.refresh()
		end)
	end,
	r = function()
		with_cursor_node(function(n)
			n.expanded = true
			runner.run(n)
		end)
	end,
	R = function()
		local root = state.root_id and state.get(state.root_id)
		if root then
			runner.run(root)
		end
	end,
	d = function()
		with_cursor_node(M.debug_test)
	end,
	p = function()
		with_cursor_node(M.peek_results)
	end,
	gf = function()
		with_cursor_node(M.goto_source)
	end,
	["<C-c>"] = function()
		state.cancel()
		vim.notify("Test run cancelled", vim.log.levels.INFO)
	end,
	D = function()
		if not state.sln_path then
			return
		end
		local root_name = vim.fn.fnamemodify(state.sln_path, ":t")
		state.clear()
		state.register({
			id = "root:" .. state.sln_path,
			display_name = root_name .. " (discovering...)",
			type = state.Type.SOLUTION,
			status = state.Status.DISCOVERING,
			expanded = true,
			parent_id = nil,
		})
		state.root_id = "root:" .. state.sln_path
		M.refresh()
		runner.discover(state.sln_path, root_name, function()
			M.refresh()
		end)
	end,
	["?"] = M.show_help,
	q = function()
		M.close()
	end,
	["<Esc>"] = function()
		M.close()
	end,
}

function M.open()
	if main_win and main_win:win_valid() then
		main_win:focus()
		return
	end

	M.setup_highlights()

	main_win = Snacks.win({
		position = "float",
		width = 0.5,
		height = 0.7,
		border = "rounded",
		title = " Test Runner ",
		title_pos = "center",
		enter = true,
		minimal = true,
		bo = { buftype = "nofile", filetype = "dotnet-test-runner", modifiable = false },
		wo = { cursorline = true, wrap = false },
		keys = {},
		on_close = function()
			stop_spinner()
			main_win = nil
		end,
		on_buf = function(self)
			for key, fn in pairs(keymap_defs) do
				vim.keymap.set("n", key, fn, { buffer = self.buf, nowait = true })
			end
		end,
	})

	state.on_update = function()
		vim.schedule(M.refresh)
	end

	M.refresh()
end

function M.close()
	stop_spinner()
	if main_win and main_win:valid() then
		main_win:close()
	end
	main_win = nil
end

function M.is_open()
	return main_win and main_win:win_valid()
end

return M
