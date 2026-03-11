--- Blink.cmp completion source for NuGet packages and versions in .csproj/.fsproj files.
--- Provides autocomplete for:
---   <PackageReference Include="|" />  -> package name suggestions
---   <PackageReference Include="Foo" Version="|" />  -> version suggestions
---
--- Register in blink.cmp sources.providers as:
---   ["nuget"] = { name = "NuGet", module = "utility.nuget-cmp", async = true, score_offset = 100 }

local M = {}

local NUGET_SEARCH_URL = "https://azuresearch-usnc.nuget.org/autocomplete?q=%s&take=20"
local NUGET_VERSIONS_URL = "https://api.nuget.org/v3-flatcontainer/%s/index.json"

--- Check if we're in a csproj/fsproj file
---@return boolean
local function is_project_file()
	local ft = vim.bo.filetype
	local fname = vim.fn.expand("%:t")
	return ft == "xml"
		or fname:match("%.csproj$")
		or fname:match("%.fsproj$")
		or fname:match("%.props$")
end

--- Determine context: are we in Include="..." or Version="..."?
---@return "package"|"version"|nil, string|nil
local function get_context()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local before = line:sub(1, col)

	-- Check if cursor is inside Version="..."
	local pkg_on_line = line:match('Include="([^"]+)"')
	local version_prefix = before:match('Version="([^"]*)')
	if version_prefix and pkg_on_line then
		return "version", pkg_on_line
	end

	-- Check if cursor is inside Include="..."
	local include_prefix = before:match('Include="([^"]*)')
	if include_prefix then
		return "package", include_prefix
	end

	return nil, nil
end

--- Fetch JSON from URL asynchronously
---@param url string
---@param callback fun(data: table|nil)
local function fetch_json(url, callback)
	vim.system(
		{ "curl", "-sL", "--max-time", "5", url },
		{ text = true },
		vim.schedule_wrap(function(result)
			if result.code ~= 0 or not result.stdout or result.stdout == "" then
				callback(nil)
				return
			end
			local ok, data = pcall(vim.json.decode, result.stdout)
			if ok then
				callback(data)
			else
				callback(nil)
			end
		end)
	)
end

-- Cache to avoid repeated API calls
local cache = {
	packages = {}, -- query -> { items, timestamp }
	versions = {}, -- package_name -> { items, timestamp }
}
local CACHE_TTL = 300 -- 5 minutes

local function cache_get(store, key)
	local entry = store[key]
	if entry and (vim.uv.now() - entry.timestamp) < CACHE_TTL * 1000 then
		return entry.items
	end
	return nil
end

local function cache_set(store, key, items)
	store[key] = { items = items, timestamp = vim.uv.now() }
end

--- blink.cmp source interface
function M.new()
	return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
	return { '"' }
end

function M:enabled()
	return is_project_file()
end

function M:get_completions(_, callback)
	if not is_project_file() then
		callback({ items = {} })
		return
	end

	local context, pkg_name = get_context()

	if context == "package" then
		local query = pkg_name or ""
		if #query < 2 then
			callback({ items = {} })
			return
		end

		local cached = cache_get(cache.packages, query)
		if cached then
			callback({ items = cached, is_incomplete_forward = true })
			return
		end

		local url = string.format(NUGET_SEARCH_URL, vim.uri_encode(query))
		fetch_json(url, function(data)
			if not data or not data.data then
				callback({ items = {} })
				return
			end

			local items = {}
			for _, name in ipairs(data.data) do
				table.insert(items, {
					label = name,
					kind = vim.lsp.protocol.CompletionItemKind.Module,
					insertText = name,
				})
			end

			cache_set(cache.packages, query, items)
			callback({ items = items, is_incomplete_forward = true })
		end)
	elseif context == "version" and pkg_name then
		local cached = cache_get(cache.versions, pkg_name)
		if cached then
			callback({ items = cached })
			return
		end

		local url = string.format(NUGET_VERSIONS_URL, pkg_name:lower())
		fetch_json(url, function(data)
			if not data or not data.versions then
				callback({ items = {} })
				return
			end

			local items = {}
			-- Show newest versions first
			for i = #data.versions, 1, -1 do
				table.insert(items, {
					label = data.versions[i],
					kind = vim.lsp.protocol.CompletionItemKind.Value,
					insertText = data.versions[i],
					sortText = string.format("%05d", #data.versions - i),
				})
			end

			cache_set(cache.versions, pkg_name, items)
			callback({ items = items })
		end)
	else
		callback({ items = {} })
	end
end

return M
