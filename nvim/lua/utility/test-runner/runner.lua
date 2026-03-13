local state = require("utility.test-runner.state")

local M = {}

-- Maps for TRX outcome -> status and stdout result -> status
local outcome_map = {
	Passed = state.Status.PASSED,
	Failed = state.Status.FAILED,
	NotExecuted = state.Status.SKIPPED,
}

local result_status_map = {
	Passed = state.Status.PASSED,
	Failed = state.Status.FAILED,
	Skipped = state.Status.SKIPPED,
}

---@return string[]
function M.find_solutions()
	local dir = vim.fn.getcwd()
	for _ = 1, 8 do
		local slns = vim.fn.glob(dir .. "/*.sln", false, true)
		vim.list_extend(slns, vim.fn.glob(dir .. "/*.slnx", false, true))
		if #slns > 0 then
			return slns
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end
	return {}
end

---@param search_dir string
---@return string[]
function M.find_test_projects(search_dir)
	local projects = {}
	for _, path in ipairs(vim.fn.globpath(search_dir, "**/*.csproj", false, true)) do
		if not path:match("/bin/") and not path:match("/obj/") and not path:match("/node_modules/") then
			local content = table.concat(vim.fn.readfile(path), "\n")
			if content:find("Microsoft%.NET%.Test%.Sdk") or content:find("<IsTestProject>true</IsTestProject>") then
				projects[#projects + 1] = path
			end
		end
	end
	return projects
end

---@param fqn string
---@return { namespace: string, class: string, method: string }
function M.parse_test_name(fqn)
	local base, params = fqn:match("^(.-)(%(.+%))$")
	base = base or fqn

	local parts = {}
	for part in base:gmatch("[^%.]+") do
		parts[#parts + 1] = part
	end

	if #parts < 2 then
		return { namespace = "", class = "", method = fqn }
	end

	local method = parts[#parts] .. (params or "")
	local class = parts[#parts - 1]
	local ns = table.concat(parts, ".", 1, #parts - 2)

	return { namespace = ns, class = class, method = method }
end

--- Register a node with common defaults
---@param opts table
local function reg(opts)
	state.register(vim.tbl_extend("keep", opts, {
		status = state.Status.IDLE,
		expanded = false,
	}))
end

--- Group tests into standalone and theories (parameterized groups)
---@param tests { fqn: string, method: string }[]
---@return { fqn: string, method: string }[], table<string, { fqn: string, method: string }[]>
local function partition_theories(tests)
	local standalone, theories = {}, {}
	for _, test in ipairs(tests) do
		local base = test.method:match("^([^%(]+)%(")
		if base then
			theories[base] = theories[base] or {}
			theories[base][#theories[base] + 1] = test
		else
			standalone[#standalone + 1] = test
		end
	end
	return standalone, theories
end

---@param root_name string
---@param root_path string
---@param project_tests table<string, string[]>
function M.build_tree(root_name, root_path, project_tests)
	state.clear()

	local root_id = "root:" .. root_path
	reg({ id = root_id, display_name = root_name, type = state.Type.SOLUTION, expanded = true })
	state.root_id = root_id

	for project_path, tests in pairs(project_tests) do
		local proj_name = vim.fn.fnamemodify(project_path, ":t:r")
		local proj_id = "proj:" .. project_path
		reg({ id = proj_id, display_name = proj_name, type = state.Type.PROJECT, expanded = true, parent_id = root_id, project_path = project_path })

		-- Group by namespace.class
		local classes = {}
		for _, fqn in ipairs(tests) do
			local parsed = M.parse_test_name(fqn)
			local key = parsed.namespace .. "." .. parsed.class
			if not classes[key] then
				classes[key] = { namespace = parsed.namespace, class = parsed.class, tests = {} }
			end
			classes[key].tests[#classes[key].tests + 1] = { fqn = fqn, method = parsed.method }
		end

		for class_key, info in pairs(classes) do
			-- Namespace node
			local parent = proj_id
			if info.namespace ~= "" then
				local ns_id = proj_id .. ":ns:" .. info.namespace
				if not state.get(ns_id) then
					reg({ id = ns_id, display_name = info.namespace, type = state.Type.NAMESPACE, expanded = true, parent_id = proj_id })
				end
				parent = ns_id
			end

			-- Class node
			local class_id = proj_id .. ":class:" .. class_key
			reg({ id = class_id, display_name = info.class, type = state.Type.CLASS, parent_id = parent })

			-- Tests: partition into standalone and theories
			local standalone, theories = partition_theories(info.tests)

			for _, test in ipairs(standalone) do
				reg({ id = "test:" .. test.fqn, display_name = test.method, type = state.Type.TEST, parent_id = class_id, fqn = test.fqn, project_path = project_path })
			end

			for base_method, cases in pairs(theories) do
				if #cases == 1 then
					reg({ id = "test:" .. cases[1].fqn, display_name = cases[1].method, type = state.Type.TEST, parent_id = class_id, fqn = cases[1].fqn, project_path = project_path })
				else
					local theory_id = class_id .. ":theory:" .. base_method
					reg({ id = theory_id, display_name = base_method .. " (" .. #cases .. " cases)", type = state.Type.THEORY, parent_id = class_id })
					for _, test in ipairs(cases) do
						local params = test.method:match("^[^%(]+(%(.*%))") or test.method
						reg({ id = "test:" .. test.fqn, display_name = params, type = state.Type.TEST, parent_id = theory_id, fqn = test.fqn, project_path = project_path })
					end
				end
			end
		end
	end
end

---@param lines string[]
---@return string[]
local function parse_test_list(lines)
	local tests, in_list = {}, false
	for _, line in ipairs(lines) do
		if line:match("The following Tests are available:") then
			in_list = true
		elseif in_list then
			local name = line:match("^%s+(.+)$")
			if name then
				tests[#tests + 1] = name
			end
		end
	end
	return tests
end

--- Collect non-empty lines from job data into a table
---@param tbl string[]
---@return fun(_: any, data: string[])
local function collect_lines(tbl)
	return function(_, data)
		for _, line in ipairs(data) do
			if line ~= "" then
				tbl[#tbl + 1] = line
			end
		end
	end
end

---@param search_dir string
---@param root_name string
---@param callback fun()
function M.discover(search_dir, root_name, callback)
	local projects = M.find_test_projects(search_dir)

	if #projects == 0 then
		vim.notify("No test projects found", vim.log.levels.WARN)
		if callback then
			callback()
		end
		return
	end

	local project_tests = {}
	local remaining = #projects
	local failed_projects = {}

	for _, project_path in ipairs(projects) do
		local output, errors = {}, {}
		vim.fn.jobstart(
			{ "dotnet", "test", project_path, "--list-tests", "--verbosity", "quiet", "--nologo" },
			{
				stdout_buffered = true,
				stderr_buffered = true,
				on_stdout = collect_lines(output),
				on_stderr = collect_lines(errors),
				on_exit = function(_, code)
					vim.schedule(function()
						local tests = parse_test_list(output)
						project_tests[project_path] = tests
						if code ~= 0 and #tests == 0 then
							failed_projects[#failed_projects + 1] = vim.fn.fnamemodify(project_path, ":t:r")
						end
						remaining = remaining - 1
						if remaining == 0 then
							M.build_tree(root_name, search_dir, project_tests)
							if #failed_projects > 0 then
								vim.notify(
									"Discovery failed for " .. #failed_projects .. " project(s): " .. table.concat(failed_projects, ", "),
									vim.log.levels.WARN
								)
							end
							if callback then
								callback()
							end
						end
					end)
				end,
			}
		)
	end
end

---@param node TestNode
---@return string|nil
function M.get_project_path(node)
	if node.project_path then
		return node.project_path
	end
	if not node.parent_id then
		return nil
	end
	local parent = state.get(node.parent_id)
	return parent and M.get_project_path(parent) or nil
end

---@param node TestNode
---@return string|nil
function M.build_filter(node)
	if node.type == state.Type.TEST then
		return node.fqn and ("FullyQualifiedName=" .. node.fqn) or nil
	elseif node.type == state.Type.THEORY then
		local base_method = node.id:match(":theory:(.+)$")
		local class_key = node.id:match(":class:(.+):theory:")
		return (base_method and class_key) and ("FullyQualifiedName~" .. class_key .. "." .. base_method) or nil
	elseif node.type == state.Type.CLASS then
		local class_key = node.id:match(":class:(.+)$")
		return class_key and ("FullyQualifiedName~" .. class_key .. ".") or nil
	elseif node.type == state.Type.NAMESPACE then
		return "FullyQualifiedName~" .. node.display_name .. "."
	end
	return nil
end

---@param line string
---@return { status: string, name: string, duration: string|nil }|nil
local function parse_result_line(line)
	for _, pattern in ipairs({
		"^%s+(Passed)%s+(.+)%s+%[(.-)%]",
		"^%s+(Failed)%s+(.+)%s+%[(.-)%]",
		"^%s+(Skipped)%s+(.+)",
	}) do
		local status, name, duration = line:match(pattern)
		if status then
			return { status = result_status_map[status], name = name:match("^%s*(.-)%s*$"), duration = duration }
		end
	end
	return nil
end

---@param s string
---@return string
local function xml_decode(s)
	local entities = { ["&lt;"] = "<", ["&gt;"] = ">", ["&amp;"] = "&", ["&apos;"] = "'", ["&quot;"] = '"' }
	s = s:gsub("&#xD;&#xA;", "\n"):gsub("&#x[AD];", "\n")
	for entity, char in pairs(entities) do
		s = s:gsub(entity, char)
	end
	return s
end

---@param filepath string
---@return table<string, { outcome: string, duration: string|nil, error_message: string|nil, stack_trace: string|nil, stdout: string|nil }>
function M.parse_trx(filepath)
	local ok, lines = pcall(vim.fn.readfile, filepath)
	if not ok then
		return {}
	end
	local content = table.concat(lines, "\n")
	local results = {}

	local function parse_block(block)
		local test_name = block:match('testName="(.-)"')
		if not test_name or results[test_name] then
			return
		end
		local message = block:match("<Message>(.-)</Message>")
		local stack = block:match("<StackTrace>(.-)</StackTrace>")
		local stdout_text = block:match("<StdOut>(.-)</StdOut>")
		results[test_name] = {
			outcome = block:match('outcome="(.-)"'),
			duration = block:match('duration="(.-)"'),
			error_message = message and xml_decode(message) or nil,
			stack_trace = stack and xml_decode(stack) or nil,
			stdout = stdout_text and xml_decode(stdout_text) or nil,
		}
	end

	for block in content:gmatch("<UnitTestResult.-</UnitTestResult>") do
		parse_block(block)
	end
	for block in content:gmatch("<UnitTestResult[^/]-/>") do
		parse_block(block)
	end
	return results
end

---@param trx_duration string
---@return string
local function format_duration(trx_duration)
	if not trx_duration then
		return ""
	end
	local h, m, s = trx_duration:match("(%d+):(%d+):([%d%.]+)")
	if not h then
		return trx_duration
	end
	local ms = ((tonumber(h) or 0) * 3600 + (tonumber(m) or 0) * 60 + (tonumber(s) or 0)) * 1000
	if ms >= 60000 then
		return string.format("%.1fm", ms / 60000)
	elseif ms >= 1000 then
		return string.format("%.1fs", ms / 1000)
	end
	return string.format("%.0fms", ms)
end

---@param node TestNode
---@param callback? fun(exit_code: number)
function M.run(node, callback)
	state.cancel()

	local project_path = M.get_project_path(node)
	local filter = M.build_filter(node)

	-- Mark running
	if node.type == state.Type.TEST then
		state.update_status(node.id, state.Status.RUNNING)
	else
		node.status = state.Status.RUNNING
		state.set_descendants_status(node.id, state.Status.RUNNING)
		if state.on_update then
			state.on_update()
		end
	end

	local tmp_dir = vim.fn.tempname()
	vim.fn.mkdir(tmp_dir, "p")
	local trx_file = tmp_dir .. "/results.trx"

	local cmd = { "dotnet", "test" }
	if not (node.type == state.Type.SOLUTION and state.sln_path) and project_path then
		cmd[#cmd + 1] = project_path
	end
	if filter then
		vim.list_extend(cmd, { "--filter", filter })
	end
	vim.list_extend(cmd, { "--logger", "trx;LogFileName=" .. trx_file, "--results-directory", tmp_dir, "--nologo", "-v", "normal" })

	local stderr_lines = {}

	state.active_job = vim.fn.jobstart(cmd, {
		on_stdout = function(_, data)
			vim.schedule(function()
				for _, line in ipairs(data) do
					local result = parse_result_line(line)
					if result then
						local test_id = "test:" .. result.name
						if state.get(test_id) then
							state.update_status(test_id, result.status, { duration = result.duration })
						end
					end
				end
			end)
		end,
		on_stderr = collect_lines(stderr_lines),
		on_exit = function(_, exit_code)
			vim.schedule(function()
				state.active_job = nil

				-- Apply TRX results
				for test_name, result in pairs(M.parse_trx(trx_file)) do
					local test_id = "test:" .. test_name
					if state.get(test_id) then
						state.update_status(test_id, outcome_map[result.outcome] or state.Status.IDLE, {
							duration = format_duration(result.duration),
							error_message = result.error_message,
							stack_trace = result.stack_trace,
							stdout = result.stdout,
						})
					end
				end

				-- Failed tests without results (build failure)
				local build_error = (exit_code ~= 0 and #stderr_lines > 0) and table.concat(stderr_lines, "\n") or nil
				for _, n in pairs(state.nodes) do
					if n.type == state.Type.TEST and n.status == state.Status.RUNNING then
						state.update_status(n.id, state.Status.FAILED, {
							error_message = build_error or "Test did not produce results (build failure?)",
						})
					end
				end

				-- Auto-expand parents of failed tests
				for _, n in pairs(state.nodes) do
					if n.type == state.Type.TEST and n.status == state.Status.FAILED and n.parent_id then
						local parent = state.get(n.parent_id)
						if parent then
							parent.expanded = true
						end
					end
				end

				vim.fn.delete(tmp_dir, "rf")

				if callback then
					callback(exit_code)
				end
			end)
		end,
	})
end

return M
