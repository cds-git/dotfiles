local M = {}

M.dotnet_build_project = function()
	local default_path = vim.fn.getcwd() .. "/"

	if vim.g["dotnet_last_proj_path"] ~= nil then
		default_path = vim.g["dotnet_last_proj_path"]
	end

	local path = vim.fn.input("Path to your *proj file: ", default_path, "file")

	vim.g["dotnet_last_proj_path"] = path

	local cmd = 'dotnet build -c Debug "' .. path

	print("\n")
	print("Cmd to execute: " .. cmd)

	local f = os.execute(cmd)

	if f == 0 then
		print("\nBuild: " .. "✔️ ")
	else
		print("\nBuild: " .. "❌" .. "(code: " .. f .. ")")
	end
end

M.dotnet_get_dll_path = function()
	local request = function()
		local label_fn = function(dll)
			return string.format("dll = %s", dll.short_path)
		end
		local procs = {}
		for _, csprojPath in ipairs(vim.fn.glob(vim.fn.getcwd() .. "**/*.csproj", false, true)) do
			local name = vim.fn.fnamemodify(csprojPath, ":t:r")
			for _, path in ipairs(vim.fn.glob(vim.fn.getcwd() .. "**/bin/**/" .. name .. ".dll", false, true)) do
				table.insert(procs, {
					path = path,
					short_path = vim.fn.fnamemodify(path, ":p:."),
				})
			end
		end

		local co, ismain = coroutine.running()
		local ui = require("dap.ui")
		local pick = (co and not ismain) and ui.pick_one or ui.pick_one_sync
		local result = pick(procs, "Select process: ", label_fn)
		return result and result.path or require("dap").ABORT
	end

	if vim.g["dotnet_last_dll_path"] == nil then
		vim.g["dotnet_last_dll_path"] = request()
	else
		if
			vim.fn.confirm("Do you want to change the path to dll?\n" .. vim.g["dotnet_last_dll_path"], "&yes\n&no", 2)
			== 1
		then
			vim.g["dotnet_last_dll_path"] = request()
		end
	end

	return vim.g["dotnet_last_dll_path"]
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
			name = "Attach",
			request = "attach",
			processId = require("dap.utils").pick_process,
		},
		{
			type = "coreclr",
			name = "Launch - netcoredbg",
			request = "launch",
			console = "integratedTerminal",
			program = function()
				if vim.fn.confirm("Should I recompile first?", "&yes\n&no", 2) == 1 then
					M.dotnet_build_project()
				end
				return M.dotnet_get_dll_path()
			end,
		},
	}
end

return M
