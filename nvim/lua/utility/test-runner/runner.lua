local state = require("utility.test-runner.state")

local M = {}

--- Find solution files (.sln and .slnx) starting from cwd, walking up
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

--- Find test projects by checking for Microsoft.NET.Test.Sdk or IsTestProject
---@param search_dir string
---@return string[]
function M.find_test_projects(search_dir)
	local projects = {}
	local csproj_files = vim.fn.globpath(search_dir, "**/*.csproj", false, true)
	for _, path in ipairs(csproj_files) do
		-- Skip bin/obj directories
		if not path:match("/bin/") and not path:match("/obj/") and not path:match("/node_modules/") then
			local content = table.concat(vim.fn.readfile(path), "\n")
			if content:find("Microsoft%.NET%.Test%.Sdk") or content:find("<IsTestProject>true</IsTestProject>") then
				table.insert(projects, path)
			end
		end
	end
	return projects
end

--- Parse test names from `dotnet test --list-tests` output
---@param lines string[]
---@return string[]
local function parse_test_list(lines)
	local tests = {}
	local in_list = false
	for _, line in ipairs(lines) do
		if line:match("The following Tests are available:") then
			in_list = true
		elseif in_list then
			local name = line:match("^%s+(.+)$")
			if name then
				table.insert(tests, name)
			end
		end
	end
	return tests
end

--- Parse a fully qualified test name into namespace, class, method
---@param fqn string
---@return { namespace: string, class: string, method: string }
function M.parse_test_name(fqn)
	-- Separate params: "Ns.Class.Method(a: 1)" -> "Ns.Class.Method", "(a: 1)"
	local base, params = fqn:match("^(.-)(%(.+%))$")
	if not base then
		base = fqn
		params = nil
	end

	local parts = {}
	for part in base:gmatch("[^%.]+") do
		table.insert(parts, part)
	end

	if #parts < 2 then
		return { namespace = "", class = "", method = fqn }
	end

	local method = parts[#parts]
	if params then
		method = method .. params
	end
	local class = parts[#parts - 1]
	local ns_parts = {}
	for i = 1, #parts - 2 do
		table.insert(ns_parts, parts[i])
	end

	return {
		namespace = table.concat(ns_parts, "."),
		class = class,
		method = method,
	}
end

--- Build the tree structure from discovered tests
---@param root_name string display name for root node
---@param root_path string path used as root id
---@param project_tests table<string, string[]>
function M.build_tree(root_name, root_path, project_tests)
	state.clear()

	local root_id = "root:" .. root_path
	state.register({
		id = root_id,
		display_name = root_name,
		type = state.Type.SOLUTION,
		status = state.Status.IDLE,
		expanded = true,
		parent_id = nil,
	})
	state.root_id = root_id

	for project_path, tests in pairs(project_tests) do
		local proj_name = vim.fn.fnamemodify(project_path, ":t:r")
		local proj_id = "proj:" .. project_path
		state.register({
			id = proj_id,
			display_name = proj_name,
			type = state.Type.PROJECT,
			status = state.Status.IDLE,
			expanded = true,
			parent_id = root_id,
			project_path = project_path,
		})

		-- Group tests by namespace.class
		local classes = {}
		for _, fqn in ipairs(tests) do
			local parsed = M.parse_test_name(fqn)
			local class_key = parsed.namespace .. "." .. parsed.class
			if not classes[class_key] then
				classes[class_key] = {
					namespace = parsed.namespace,
					class = parsed.class,
					tests = {},
				}
			end
			table.insert(classes[class_key].tests, { fqn = fqn, method = parsed.method })
		end

		for class_key, info in pairs(classes) do
			local parent = proj_id

			-- Create namespace node if non-empty
			if info.namespace ~= "" then
				local ns_id = proj_id .. ":ns:" .. info.namespace
				if not state.get(ns_id) then
					state.register({
						id = ns_id,
						display_name = info.namespace,
						type = state.Type.NAMESPACE,
						status = state.Status.IDLE,
						expanded = true,
						parent_id = proj_id,
					})
				end
				parent = ns_id
			end

			-- Create class node
			local class_id = proj_id .. ":class:" .. class_key
			state.register({
				id = class_id,
				display_name = info.class,
				type = state.Type.CLASS,
				status = state.Status.IDLE,
				expanded = false,
				parent_id = parent,
			})

			-- Group parameterized tests (theories) by base method name
			local theories = {} -- base_method -> list of tests
			local standalone = {} -- tests without params
			for _, test in ipairs(info.tests) do
				local base_method, params = test.method:match("^([^%(]+)(%(.*%))")
				if params then
					if not theories[base_method] then
						theories[base_method] = {}
					end
					table.insert(theories[base_method], test)
				else
					table.insert(standalone, test)
				end
			end

			-- Create standalone test nodes directly under the class
			for _, test in ipairs(standalone) do
				state.register({
					id = "test:" .. test.fqn,
					display_name = test.method,
					type = state.Type.TEST,
					status = state.Status.IDLE,
					expanded = false,
					parent_id = class_id,
					fqn = test.fqn,
					project_path = project_path,
				})
			end

			-- Create theory group nodes for parameterized tests
			for base_method, cases in pairs(theories) do
				if #cases == 1 then
					-- Single case, no need for a group
					state.register({
						id = "test:" .. cases[1].fqn,
						display_name = cases[1].method,
						type = state.Type.TEST,
						status = state.Status.IDLE,
						expanded = false,
						parent_id = class_id,
						fqn = cases[1].fqn,
						project_path = project_path,
					})
				else
					-- Create a collapsible theory group
					local theory_id = class_id .. ":theory:" .. base_method
					state.register({
						id = theory_id,
						display_name = base_method .. " (" .. #cases .. " cases)",
						type = state.Type.THEORY,
						status = state.Status.IDLE,
						expanded = false,
						parent_id = class_id,
					})
					for _, test in ipairs(cases) do
						-- Show just the params as display name under the theory
						local params = test.method:match("^[^%(]+(%(.*%))") or test.method
						state.register({
							id = "test:" .. test.fqn,
							display_name = params,
							type = state.Type.TEST,
							status = state.Status.IDLE,
							expanded = false,
							parent_id = theory_id,
							fqn = test.fqn,
							project_path = project_path,
						})
					end
				end
			end
		end
	end
end

--- Discover tests across all test projects asynchronously
---@param search_dir string directory to search for test projects
---@param root_name string display name for root
---@param callback fun()
function M.discover(search_dir, root_name, callback)
	local projects = M.find_test_projects(search_dir)

	if #projects == 0 then
		vim.notify("No test projects found (looking for Microsoft.NET.Test.Sdk or IsTestProject)", vim.log.levels.WARN)
		if callback then
			callback()
		end
		return
	end

	local project_tests = {}
	local remaining = #projects

	for _, project_path in ipairs(projects) do
		local output = {}
		local errors = {}
		local proj_name = vim.fn.fnamemodify(project_path, ":t:r")
		vim.fn.jobstart({
			"dotnet",
			"test",
			project_path,
			"--list-tests",
			"--verbosity",
			"quiet",
			"--nologo",
		}, {
			stdout_buffered = true,
			stderr_buffered = true,
			on_stdout = function(_, data)
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(output, line)
					end
				end
			end,
			on_stderr = function(_, data)
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(errors, line)
					end
				end
			end,
			on_exit = function(_, code)
				vim.schedule(function()
					local tests = parse_test_list(output)
					project_tests[project_path] = tests
					if code ~= 0 and #tests == 0 then
						vim.notify(
							"Discovery failed for " .. proj_name .. ":\n" .. table.concat(errors, "\n"),
							vim.log.levels.WARN
						)
					end
					remaining = remaining - 1
					if remaining == 0 then
						M.build_tree(root_name, search_dir, project_tests)
						if callback then
							callback()
						end
					end
				end)
			end,
		})
	end
end

--- Walk up from a node to find its project path
---@param node TestNode
---@return string|nil
function M.get_project_path(node)
	if node.project_path then
		return node.project_path
	end
	if node.parent_id then
		local parent = state.get(node.parent_id)
		if parent then
			return M.get_project_path(parent)
		end
	end
	return nil
end

--- Build a --filter expression for a given node
---@param node TestNode
---@return string|nil
function M.build_filter(node)
	if node.type == state.Type.TEST then
		local fqn = node.fqn
		if not fqn then
			return nil
		end
		return "FullyQualifiedName=" .. fqn
	elseif node.type == state.Type.THEORY then
		-- Theory node: match the base method name (without params)
		local base_method = node.id:match(":theory:(.+)$")
		local class_key = node.id:match(":class:(.+):theory:")
		if base_method and class_key then
			return "FullyQualifiedName~" .. class_key .. "." .. base_method
		end
	elseif node.type == state.Type.CLASS then
		local class_key = node.id:match(":class:(.+)$")
		if class_key then
			return "FullyQualifiedName~" .. class_key .. "."
		end
	elseif node.type == state.Type.NAMESPACE then
		return "FullyQualifiedName~" .. node.display_name .. "."
	end
	return nil -- run all (project or solution level)
end

--- Parse a real-time stdout line for test results
---@param line string
---@return { status: string, name: string, duration: string|nil }|nil
local function parse_result_line(line)
	local status, name, duration
	-- "  Passed TestName [42ms]"
	status, name, duration = line:match("^%s+(Passed)%s+(.+)%s+%[(.-)%]")
	if not status then
		status, name, duration = line:match("^%s+(Failed)%s+(.+)%s+%[(.-)%]")
	end
	if not status then
		status, name = line:match("^%s+(Skipped)%s+(.+)")
	end
	if status then
		local s
		if status == "Passed" then
			s = state.Status.PASSED
		elseif status == "Failed" then
			s = state.Status.FAILED
		else
			s = state.Status.SKIPPED
		end
		if name then
			name = name:match("^%s*(.-)%s*$")
		end
		return { status = s, name = name, duration = duration }
	end
	return nil
end

--- Decode common XML entities
---@param s string
---@return string
local function xml_decode(s)
	return s
		:gsub("&lt;", "<")
		:gsub("&gt;", ">")
		:gsub("&amp;", "&")
		:gsub("&#xD;&#xA;", "\n")
		:gsub("&#xA;", "\n")
		:gsub("&#xD;", "\n")
		:gsub("&apos;", "'")
		:gsub("&quot;", '"')
end

--- Parse a TRX file for detailed test results
---@param filepath string
---@return table<string, { outcome: string, duration: string|nil, error_message: string|nil, stack_trace: string|nil, stdout: string|nil }>
function M.parse_trx(filepath)
	local ok, lines = pcall(vim.fn.readfile, filepath)
	if not ok then
		return {}
	end
	local content = table.concat(lines, "\n")
	local results = {}

	-- Match UnitTestResult elements with content
	for block in content:gmatch("<UnitTestResult.-</UnitTestResult>") do
		local test_name = block:match('testName="(.-)"')
		local outcome = block:match('outcome="(.-)"')
		local duration = block:match('duration="(.-)"')
		local message = block:match("<Message>(.-)</Message>")
		local stack = block:match("<StackTrace>(.-)</StackTrace>")
		local stdout_text = block:match("<StdOut>(.-)</StdOut>")

		if test_name then
			results[test_name] = {
				outcome = outcome,
				duration = duration,
				error_message = message and xml_decode(message) or nil,
				stack_trace = stack and xml_decode(stack) or nil,
				stdout = stdout_text and xml_decode(stdout_text) or nil,
			}
		end
	end

	-- Self-closing UnitTestResult elements (common for passed tests)
	for block in content:gmatch("<UnitTestResult[^/]-/>") do
		local test_name = block:match('testName="(.-)"')
		local outcome = block:match('outcome="(.-)"')
		local duration = block:match('duration="(.-)"')
		if test_name and not results[test_name] then
			results[test_name] = {
				outcome = outcome,
				duration = duration,
			}
		end
	end

	return results
end

--- Format a TRX duration (00:00:00.0423) to a short display string
---@param trx_duration string
---@return string
local function format_duration(trx_duration)
	if not trx_duration then
		return ""
	end
	local h, m, s = trx_duration:match("(%d+):(%d+):([%d%.]+)")
	if h then
		local hours = tonumber(h) or 0
		local mins = tonumber(m) or 0
		local secs = tonumber(s) or 0
		local total_ms = (hours * 3600 + mins * 60 + secs) * 1000
		if total_ms >= 60000 then
			return string.format("%.1fm", total_ms / 60000)
		elseif total_ms >= 1000 then
			return string.format("%.1fs", total_ms / 1000)
		else
			return string.format("%.0fms", total_ms)
		end
	end
	return trx_duration
end

--- Run tests for a given node asynchronously
---@param node TestNode
---@param callback? fun(exit_code: number)
function M.run(node, callback)
	-- Cancel any active run
	state.cancel()

	local project_path = M.get_project_path(node)
	local filter = M.build_filter(node)

	-- Mark tests as running
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
	if node.type == state.Type.SOLUTION and state.sln_path then
		-- Run on solution or workspace root
		-- Don't pass a path, let dotnet figure it out from cwd
	elseif project_path then
		table.insert(cmd, project_path)
	end
	if filter then
		table.insert(cmd, "--filter")
		table.insert(cmd, filter)
	end
	vim.list_extend(cmd, {
		"--logger",
		"trx;LogFileName=" .. trx_file,
		"--results-directory",
		tmp_dir,
		"--nologo",
		"-v",
		"normal",
	})

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
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				if line ~= "" then
					table.insert(stderr_lines, line)
				end
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				state.active_job = nil

				-- Parse TRX for detailed results (error messages, stack traces)
				local trx_results = M.parse_trx(trx_file)
				for test_name, result in pairs(trx_results) do
					local test_id = "test:" .. test_name
					local test_node = state.get(test_id)
					if test_node then
						local s
						if result.outcome == "Passed" then
							s = state.Status.PASSED
						elseif result.outcome == "Failed" then
							s = state.Status.FAILED
						elseif result.outcome == "NotExecuted" then
							s = state.Status.SKIPPED
						else
							s = state.Status.IDLE
						end
						state.update_status(test_id, s, {
							duration = format_duration(result.duration),
							error_message = result.error_message,
							stack_trace = result.stack_trace,
							stdout = result.stdout,
						})
					end
				end

				-- Build the error output for failed tests without TRX results
				local build_error = nil
				if exit_code ~= 0 and #stderr_lines > 0 then
					build_error = table.concat(stderr_lines, "\n")
				end

				-- Any tests still marked as running had no results (build failure?)
				for _, n in pairs(state.nodes) do
					if n.type == state.Type.TEST and n.status == state.Status.RUNNING then
						state.update_status(n.id, state.Status.FAILED, {
							error_message = build_error or "Test did not produce results (build failure?)",
						})
					end
				end

				-- Auto-expand classes that contain failed tests
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
