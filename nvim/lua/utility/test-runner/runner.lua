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
---@return { path: string, uses_mtp: boolean }[]
function M.find_test_projects(search_dir)
	local projects = {}
	for _, path in ipairs(vim.fn.globpath(search_dir, "**/*.csproj", false, true)) do
		if not path:match("/bin/") and not path:match("/obj/") and not path:match("/node_modules/") then
			local content = table.concat(vim.fn.readfile(path), "\n")
			if content:find("Microsoft%.NET%.Test%.Sdk") or content:find("<IsTestProject>true</IsTestProject>") then
				local uses_mtp = content:find("TestingPlatformDotnetTestSupport") ~= nil
				projects[#projects + 1] = { path = path, uses_mtp = uses_mtp }
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
---@param project_tests table<string, { tests: string[], uses_mtp: boolean }>
function M.build_tree(root_name, root_path, project_tests)
	state.clear()

	local root_id = "root:" .. root_path
	reg({ id = root_id, display_name = root_name, type = state.Type.SOLUTION, expanded = true })
	state.root_id = root_id

	for project_path, info in pairs(project_tests) do
		local tests = info.tests
		local proj_name = vim.fn.fnamemodify(project_path, ":t:r")
		local proj_id = "proj:" .. project_path
		reg({ id = proj_id, display_name = proj_name, type = state.Type.PROJECT, expanded = true, parent_id = root_id, project_path = project_path, uses_mtp = info.uses_mtp })

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

--- Parse VSTest format: lines after "The following Tests are available:"
---@param lines string[]
---@return string[]
local function parse_vstest_list(lines)
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

--- Parse xUnit v3 native format: one FQN per line (skips the header line)
---@param lines string[]
---@return string[]
local function parse_xunit_list(lines)
	local tests = {}
	for _, line in ipairs(lines) do
		-- Skip empty lines and the xUnit header "xUnit.net v3 ..."
		if line ~= "" and not line:match("^xUnit%.net") then
			local name = line:match("^%s*(.+%..+)%s*$")
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

	local function on_project_done()
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
	end

	--- Discover via VSTest: dotnet test --list-tests
	local function discover_vstest(project)
		local output, errors = {}, {}
		vim.fn.jobstart(
			{ "dotnet", "test", project.path, "--list-tests", "--verbosity", "quiet", "--nologo" },
			{
				stdout_buffered = true,
				stderr_buffered = true,
				on_stdout = collect_lines(output),
				on_stderr = collect_lines(errors),
				on_exit = function(_, code)
					vim.schedule(function()
						local tests = parse_vstest_list(output)
						project_tests[project.path] = { tests = tests, uses_mtp = false }
						if code ~= 0 and #tests == 0 then
							failed_projects[#failed_projects + 1] = vim.fn.fnamemodify(project.path, ":t:r")
						end
						on_project_done()
					end)
				end,
			}
		)
	end

	--- Discover via MTP: build then run DLL with -list tests
	local function discover_mtp(project)
		local proj_name = vim.fn.fnamemodify(project.path, ":t:r")
		local proj_dir = vim.fn.fnamemodify(project.path, ":h")

		vim.fn.jobstart({ "dotnet", "build", project.path, "--verbosity", "quiet", "--nologo" }, {
			stdout_buffered = true,
			stderr_buffered = true,
			on_exit = function(_, build_code)
				vim.schedule(function()
					if build_code ~= 0 then
						project_tests[project.path] = { tests = {}, uses_mtp = true }
						failed_projects[#failed_projects + 1] = proj_name
						on_project_done()
						return
					end

					-- Find the built DLL
					local dlls = vim.fn.glob(proj_dir .. "/bin/Debug/**/" .. proj_name .. ".dll", false, true)
					if #dlls == 0 then
						project_tests[project.path] = { tests = {}, uses_mtp = true }
						failed_projects[#failed_projects + 1] = proj_name
						on_project_done()
						return
					end

					-- Run xUnit v3 native list
					local output = {}
					vim.fn.jobstart({ "dotnet", "exec", dlls[1], "-list", "tests" }, {
						stdout_buffered = true,
						stderr_buffered = true,
						on_stdout = collect_lines(output),
						on_exit = function(_, list_code)
							vim.schedule(function()
								local tests = parse_xunit_list(output)
								project_tests[project.path] = { tests = tests, uses_mtp = true }
								if list_code ~= 0 and #tests == 0 then
									failed_projects[#failed_projects + 1] = proj_name
								end
								on_project_done()
							end)
						end,
					})
				end)
			end,
		})
	end

	for _, project in ipairs(projects) do
		if project.uses_mtp then
			discover_mtp(project)
		else
			discover_vstest(project)
		end
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

--- Check if a node belongs to an MTP project
---@param node TestNode
---@return boolean
function M.get_uses_mtp(node)
	if node.uses_mtp ~= nil then
		return node.uses_mtp
	end
	-- For SOLUTION nodes, check if any child project uses MTP
	if node.type == state.Type.SOLUTION then
		for _, child in ipairs(state.children(node.id)) do
			if child.uses_mtp then
				return true
			end
		end
		return false
	end
	if not node.parent_id then
		return false
	end
	local parent = state.get(node.parent_id)
	return parent and M.get_uses_mtp(parent) or false
end

--- Build a VSTest --filter expression
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

--- Build xUnit v3 native -method and -class args for MTP projects
---@param node TestNode
---@return string[]
function M.build_mtp_filter_args(node)
	if node.type == state.Type.TEST then
		local base = node.fqn and (node.fqn:match("^(.-)%(") or node.fqn) or nil
		return base and { "-method", base } or {}
	elseif node.type == state.Type.THEORY then
		local base_method = node.id:match(":theory:(.+)$")
		local class_key = node.id:match(":class:(.+):theory:")
		return (base_method and class_key) and { "-method", class_key .. "." .. base_method } or {}
	elseif node.type == state.Type.CLASS then
		local class_key = node.id:match(":class:(.+)$")
		return class_key and { "-class", class_key } or {}
	elseif node.type == state.Type.NAMESPACE then
		return { "-namespace", node.display_name }
	end
	return {}
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

--- Apply TRX results from one or more files
---@param trx_paths string[]
local function apply_trx_results(trx_paths)
	for _, trx_file in ipairs(trx_paths) do
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
	end
end

--- Mark remaining RUNNING tests after a run completes
---@param exit_code number
---@param stderr_lines string[]
---@param project_path string|nil  -- nil = all tests
local function finalize_running_tests(exit_code, stderr_lines, project_path)
	local build_error = (exit_code ~= 0 and #stderr_lines > 0) and table.concat(stderr_lines, "\n") or nil
	for _, n in pairs(state.nodes) do
		if n.type == state.Type.TEST and n.status == state.Status.RUNNING then
			if not project_path or n.project_path == project_path then
				if exit_code ~= 0 then
					state.update_status(n.id, state.Status.FAILED, {
						error_message = build_error or "Test did not produce results (build failure?)",
					})
				else
					-- Tests passed overall but these weren't in TRX/stdout — reset to idle
					state.update_status(n.id, state.Status.IDLE)
				end
			end
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
end

--- Common exit handler for test runs
---@param trx_file string
---@param tmp_dir string
---@param stderr_lines string[]
---@param project_path string|nil  -- scope "mark remaining as failed" to this project only
---@param callback? fun(exit_code: number)
---@return fun(exit_code: number)
local function make_on_exit(trx_file, tmp_dir, stderr_lines, project_path, callback)
	return function(_, exit_code)
		vim.schedule(function()
			state.active_job = nil
			apply_trx_results({ trx_file })
			finalize_running_tests(exit_code, stderr_lines, project_path)
			vim.fn.delete(tmp_dir, "rf")
			if callback then
				callback(exit_code)
			end
		end)
	end
end

--- Run a single MTP project node
---@param node TestNode
---@param project_path string
---@param tmp_dir string
---@param trx_file string
---@param callback? fun(exit_code: number)
local function run_mtp(node, project_path, tmp_dir, trx_file, callback)
	local proj_name = vim.fn.fnamemodify(project_path, ":t:r")
	local proj_dir = vim.fn.fnamemodify(project_path, ":h")
	local stderr_lines = {}
	local dlls = vim.fn.glob(proj_dir .. "/bin/Debug/**/" .. proj_name .. ".dll", false, true)

	local function start_test(dll)
		local cmd = { "dotnet", "exec", dll }
		vim.list_extend(cmd, M.build_mtp_filter_args(node))
		vim.list_extend(cmd, { "-trx", trx_file })
		return vim.fn.jobstart(cmd, {
			on_stderr = collect_lines(stderr_lines),
			on_exit = make_on_exit(trx_file, tmp_dir, stderr_lines, project_path, callback),
		})
	end

	if #dlls == 0 then
		return vim.fn.jobstart({ "dotnet", "build", project_path, "--verbosity", "quiet", "--nologo" }, {
			on_exit = function(_, build_code)
				vim.schedule(function()
					if build_code ~= 0 then
						for _, n in pairs(state.nodes) do
							if n.type == state.Type.TEST and n.status == state.Status.RUNNING and n.project_path == project_path then
								state.update_status(n.id, state.Status.FAILED, { error_message = "Build failed" })
							end
						end
						if callback then
							callback(build_code)
						end
						return
					end
					dlls = vim.fn.glob(proj_dir .. "/bin/Debug/**/" .. proj_name .. ".dll", false, true)
					if #dlls == 0 then
						if callback then
							callback(1)
						end
						return
					end
					state.active_job = start_test(dlls[1])
				end)
			end,
		})
	end

	return start_test(dlls[1])
end

--- Run a single VSTest project/node
---@param node TestNode
---@param project_path string|nil
---@param tmp_dir string
---@param trx_file string
---@param callback? fun(exit_code: number)
local function run_vstest(node, project_path, tmp_dir, trx_file, callback)
	local stderr_lines = {}
	local filter = M.build_filter(node)
	local cmd = { "dotnet", "test" }
	if project_path then
		cmd[#cmd + 1] = project_path
	end
	if filter then
		vim.list_extend(cmd, { "--filter", filter })
	end
	vim.list_extend(cmd, { "--logger", "trx;LogFileName=" .. trx_file, "--results-directory", tmp_dir, "--nologo", "-v", "normal" })

	return vim.fn.jobstart(cmd, {
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
		on_exit = make_on_exit(trx_file, tmp_dir, stderr_lines, project_path, callback),
	})
end

---@param node TestNode
---@param callback? fun(exit_code: number)
function M.run(node, callback)
	state.cancel()

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

	-- SOLUTION-level: single dotnet test command (matches CLI behavior and performance)
	if node.type == state.Type.SOLUTION then
		local sln_file = state.sln_path .. "/" .. node.display_name
		local tmp_dir = vim.fn.tempname()
		vim.fn.mkdir(tmp_dir, "p")
		local stderr_lines = {}

		-- Check for MTP projects that need separate execution
		local mtp_projects = {}
		for _, proj in ipairs(state.children(node.id)) do
			if proj.type == state.Type.PROJECT and proj.uses_mtp then
				mtp_projects[#mtp_projects + 1] = proj
			end
		end

		local remaining = 1 + #mtp_projects
		local any_failed = false
		local jobs = {}

		local function on_part_done(exit_code)
			if exit_code ~= 0 then
				any_failed = true
			end
			remaining = remaining - 1
			if remaining == 0 then
				state.active_job = nil
				if callback then
					callback(any_failed and 1 or 0)
				end
			end
		end

		-- Single dotnet test on the solution
		local sln_job = vim.fn.jobstart({
			"dotnet", "test", sln_file,
			"--logger", "trx",
			"--results-directory", tmp_dir,
			"--nologo", "-v", "normal",
		}, {
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
					-- Parse all TRX files in the results directory
					local trx_files = vim.fn.glob(tmp_dir .. "/*.trx", false, true)
					apply_trx_results(trx_files)

					-- Finalize remaining RUNNING tests (only non-MTP)
					for _, n in pairs(state.nodes) do
						if n.type == state.Type.TEST and n.status == state.Status.RUNNING then
							local proj = n.project_path and state.get("proj:" .. n.project_path)
							if not proj or not proj.uses_mtp then
								if exit_code ~= 0 then
									local build_error = #stderr_lines > 0 and table.concat(stderr_lines, "\n") or nil
									state.update_status(n.id, state.Status.FAILED, {
										error_message = build_error or "Test did not produce results (build failure?)",
									})
								else
									state.update_status(n.id, state.Status.IDLE)
								end
							end
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
					on_part_done(exit_code)
				end)
			end,
		})
		jobs[#jobs + 1] = sln_job

		-- MTP projects need separate execution
		for _, proj in ipairs(mtp_projects) do
			local mtp_tmp = vim.fn.tempname()
			vim.fn.mkdir(mtp_tmp, "p")
			local trx_file = mtp_tmp .. "/results.trx"
			jobs[#jobs + 1] = run_mtp(proj, proj.project_path, mtp_tmp, trx_file, on_part_done)
		end

		state.active_jobs = jobs
		return
	end

	-- Non-solution nodes: single project run
	local project_path = M.get_project_path(node)
	local uses_mtp = M.get_uses_mtp(node)
	local tmp_dir = vim.fn.tempname()
	vim.fn.mkdir(tmp_dir, "p")
	local trx_file = tmp_dir .. "/results.trx"

	if uses_mtp then
		if not project_path then
			vim.notify("No MTP project found", vim.log.levels.ERROR)
			return
		end
		state.active_job = run_mtp(node, project_path, tmp_dir, trx_file, callback)
	else
		state.active_job = run_vstest(node, project_path, tmp_dir, trx_file, callback)
	end
end

return M
