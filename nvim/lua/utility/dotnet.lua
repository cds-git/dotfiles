local M = {}

--- Find all .csproj/.fsproj files under cwd
---@return { name: string, path: string, short_path: string }[]
local function find_projects()
	local projects = {}
	local cwd = vim.fn.getcwd()
	for _, pattern in ipairs({ "**/*.csproj", "**/*.fsproj" }) do
		for _, path in ipairs(vim.fn.glob(cwd .. "/" .. pattern, false, true)) do
			table.insert(projects, {
				name = vim.fn.fnamemodify(path, ":t:r"),
				path = path,
				short_path = vim.fn.fnamemodify(path, ":p:."),
			})
		end
	end
	return projects
end

--- Find all debug DLLs matching discovered projects
---@return { name: string, path: string, short_path: string }[]
local function find_debug_dlls()
	local dlls = {}
	local cwd = vim.fn.getcwd()
	for _, proj in ipairs(find_projects()) do
		for _, path in ipairs(vim.fn.glob(cwd .. "/**/bin/Debug/**/" .. proj.name .. ".dll", false, true)) do
			table.insert(dlls, {
				name = proj.name,
				path = path,
				short_path = vim.fn.fnamemodify(path, ":p:."),
			})
		end
	end
	return dlls
end

--- Pick a project using Snacks picker, then call on_select with it
---@param opts { title: string }
---@param on_select fun(project: { name: string, path: string, short_path: string })
local function pick_project(opts, on_select)
	local projects = find_projects()
	if #projects == 0 then
		vim.notify("No .csproj or .fsproj files found", vim.log.levels.WARN)
		return
	end
	if #projects == 1 then
		on_select(projects[1])
		return
	end

	Snacks.picker({
		title = opts.title or "Select Project",
		items = vim.tbl_map(function(p)
			return { text = p.name, item = p }
		end, projects),
		format = function(item)
			return { { item.text, "Normal" } }
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				on_select(item.item)
			end
		end,
	})
end

--- Build a project (async via vim.system)
---@param project_path string
---@param on_done? fun(ok: boolean)
local function build_project(project_path, on_done)
	vim.notify("Building " .. vim.fn.fnamemodify(project_path, ":t:r") .. "...", vim.log.levels.INFO)
	vim.system(
		{ "dotnet", "build", "-c", "Debug", project_path },
		{ text = true },
		vim.schedule_wrap(function(result)
			if result.code == 0 then
				vim.notify("Build succeeded", vim.log.levels.INFO)
			else
				vim.notify("Build failed:\n" .. (result.stderr or result.stdout or ""), vim.log.levels.ERROR)
			end
			if on_done then
				on_done(result.code == 0)
			end
		end)
	)
end

--- Parse project references from a .csproj/.fsproj file
---@param project_path string
---@return string[]
local function get_project_references(project_path)
	local refs = {}
	local dir = vim.fn.fnamemodify(project_path, ":h")
	local lines = vim.fn.readfile(project_path)
	for _, line in ipairs(lines) do
		local include = line:match('<ProjectReference%s+Include="([^"]+)"')
		if include then
			-- Normalize path separators and resolve relative to project dir
			include = include:gsub("\\", "/")
			local abs = vim.fn.simplify(dir .. "/" .. include)
			table.insert(refs, {
				raw = include,
				abs = abs,
				name = vim.fn.fnamemodify(abs, ":t:r"),
			})
		end
	end
	return refs
end

--- Parse package references from a .csproj/.fsproj file
---@param project_path string
---@return { name: string, version: string }[]
local function get_package_references(project_path)
	local pkgs = {}
	local lines = vim.fn.readfile(project_path)
	for _, line in ipairs(lines) do
		local name = line:match('<PackageReference%s+Include="([^"]+)"')
		local version = line:match('Version="([^"]+)"')
		if name then
			table.insert(pkgs, { name = name, version = version or "?" })
		end
	end
	return pkgs
end

--- Show a project view buffer with references and packages
M.project_view = function()
	pick_project({ title = "Project View" }, function(project)
		local proj_refs = get_project_references(project.path)
		local pkg_refs = get_package_references(project.path)

		local lines = {}
		table.insert(lines, "# " .. project.name)
		table.insert(lines, "  " .. project.short_path)
		table.insert(lines, "")

		table.insert(lines, "## Project References (" .. #proj_refs .. ")")
		if #proj_refs == 0 then
			table.insert(lines, "  (none)")
		else
			for _, ref in ipairs(proj_refs) do
				table.insert(lines, "  " .. ref.name)
			end
		end
		table.insert(lines, "")

		table.insert(lines, "## Package References (" .. #pkg_refs .. ")")
		if #pkg_refs == 0 then
			table.insert(lines, "  (none)")
		else
			for _, pkg in ipairs(pkg_refs) do
				table.insert(lines, "  " .. pkg.name .. "  " .. pkg.version)
			end
		end

		-- Open in a floating scratch buffer
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].filetype = "markdown"
		vim.bo[buf].modifiable = false
		vim.bo[buf].bufhidden = "wipe"

		local width = math.min(80, vim.o.columns - 10)
		local height = math.min(#lines + 2, vim.o.lines - 10)
		vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			col = math.floor((vim.o.columns - width) / 2),
			row = math.floor((vim.o.lines - height) / 2),
			style = "minimal",
			border = "rounded",
			title = " " .. project.name .. " ",
			title_pos = "center",
		})

		-- q to close
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, nowait = true })
	end)
end

--- Add a project reference: pick source project, then pick target to reference
M.add_reference = function()
	pick_project({ title = "Add reference TO which project?" }, function(target)
		local all = find_projects()
		-- Filter out the target itself and projects already referenced
		local existing_refs = get_project_references(target.path)
		local existing_names = {}
		for _, ref in ipairs(existing_refs) do
			existing_names[ref.name] = true
		end

		local candidates = vim.tbl_filter(function(p)
			return p.path ~= target.path and not existing_names[p.name]
		end, all)

		if #candidates == 0 then
			vim.notify("No projects available to reference (all already referenced or only one project)", vim.log.levels.INFO)
			return
		end

		Snacks.picker({
			title = "Add reference FROM",
			items = vim.tbl_map(function(p)
				return { text = p.name, item = p }
			end, candidates),
			format = function(item)
				return { { item.text, "Normal" } }
			end,
			confirm = function(picker, item)
				picker:close()
				if not item then
					return
				end

				local ref = item.item
				vim.system(
					{ "dotnet", "add", target.path, "reference", ref.path },
					{ text = true },
					vim.schedule_wrap(function(result)
						if result.code == 0 then
							vim.notify("Added reference: " .. target.name .. " -> " .. ref.name, vim.log.levels.INFO)
						else
							vim.notify("Failed to add reference:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
						end
					end)
				)
			end,
		})
	end)
end

--- Remove a project reference from a project
M.remove_reference = function()
	pick_project({ title = "Remove reference FROM which project?" }, function(target)
		local refs = get_project_references(target.path)
		if #refs == 0 then
			vim.notify(target.name .. " has no project references", vim.log.levels.INFO)
			return
		end

		Snacks.picker({
			title = "Remove reference",
			items = vim.tbl_map(function(r)
				return { text = r.name, item = r }
			end, refs),
			format = function(item)
				return { { item.text, "Normal" } }
			end,
			confirm = function(picker, item)
				picker:close()
				if not item then
					return
				end

				local ref = item.item
				vim.system(
					{ "dotnet", "remove", target.path, "reference", ref.abs },
					{ text = true },
					vim.schedule_wrap(function(result)
						if result.code == 0 then
							vim.notify("Removed reference: " .. ref.name .. " from " .. target.name, vim.log.levels.INFO)
						else
							vim.notify("Failed to remove reference:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
						end
					end)
				)
			end,
		})
	end)
end

--- Attach to a running .NET process by name filter.
M.attach_to_process = function()
	local dap = require("dap")

	local co = coroutine.create(function()
		local filter = vim.fn.input("Process name filter (e.g. MyApi, empty for dotnet): ")
		if filter == "" then
			filter = "dotnet"
		end

		dap.run({
			type = "coreclr",
			name = "Attach - " .. filter,
			request = "attach",
			processId = function()
				return require("dap.utils").pick_process({ filter = filter })
			end,
		})
	end)
	coroutine.resume(co)
end

--- Pick a project and launch the debugger
M.debug_project = function()
	local dap = require("dap")

	pick_project({ title = "Debug Project" }, function(project)
		vim.notify("Building " .. project.name .. " before debug...", vim.log.levels.INFO)
		build_project(project.path, function(ok)
			if not ok then
				return
			end

			local cwd = vim.fn.getcwd()
			local dlls = vim.fn.glob(cwd .. "/**/bin/Debug/**/" .. project.name .. ".dll", false, true)
			if #dlls == 0 then
				vim.notify("No debug DLL found for " .. project.name, vim.log.levels.ERROR)
				return
			end

			dap.run({
				type = "coreclr",
				name = "Launch - " .. project.name,
				request = "launch",
				console = "integratedTerminal",
				program = dlls[1],
			})
		end)
	end)
end

M.setup_debug = function()
	local dap = require("dap")
	local netcoredbg_install_dir = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg"

	if vim.fn.has("win32") == 1 then
		netcoredbg_install_dir = netcoredbg_install_dir .. "/netcoredbg.exe"
	end

	dap.adapters.coreclr = {
		type = "executable",
		command = netcoredbg_install_dir,
		args = { "--interpreter=vscode" },
	}

	dap.configurations.cs = {
		{
			type = "coreclr",
			name = "Attach to Process",
			request = "attach",
			processId = function()
				local filter = vim.fn.input("Process name filter (empty for all): ")
				if filter == "" then
					return require("dap.utils").pick_process()
				end
				return require("dap.utils").pick_process({ filter = filter })
			end,
		},
		{
			type = "coreclr",
			name = "Launch (pick DLL)",
			request = "launch",
			console = "integratedTerminal",
			program = function()
				local co, is_main = coroutine.running()
				if not co or is_main then
					local dlls = find_debug_dlls()
					if #dlls == 0 then
						return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
					end
					if #dlls == 1 then
						return dlls[1].path
					end
					local items = {}
					for i, d in ipairs(dlls) do
						table.insert(items, i .. ". " .. d.short_path)
					end
					local choice = vim.fn.inputlist(vim.list_extend({ "Select DLL:" }, items))
					if choice > 0 and choice <= #dlls then
						return dlls[choice].path
					end
					return require("dap").ABORT
				end

				-- Async path: use dap.ui picker inside coroutine
				local ui = require("dap.ui")
				local dlls = find_debug_dlls()
				if #dlls == 0 then
					return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
				end
				local result = ui.pick_one(dlls, "Select DLL: ", function(d)
					return d.short_path
				end)
				return result and result.path or require("dap").ABORT
			end,
		},
	}
end

--- Setup user commands
M.setup_commands = function()
	vim.api.nvim_create_user_command("DotnetProjectView", M.project_view, { desc = "View .NET project details" })
	vim.api.nvim_create_user_command("DotnetAddReference", M.add_reference, { desc = "Add a project reference" })
	vim.api.nvim_create_user_command("DotnetRemoveReference", M.remove_reference, { desc = "Remove a project reference" })
	vim.api.nvim_create_user_command("DotnetDebug", M.debug_project, { desc = "Build & debug a .NET project" })
end

return M
