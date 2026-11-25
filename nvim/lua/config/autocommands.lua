-- Parameter types of the method named `name` in a hover signature, e.g.
-- "Task<X> IHandler<Cmd, X>.HandleAsync(Cmd command, [CancellationToken ct = default])"
-- gives { "Cmd", "CancellationToken" }. Nil when the hover holds no such call.
local function hover_param_types(hover, name)
	local start = hover:find("%f[%w_]" .. vim.pesc(name) .. "%s*%(")
	if not start then
		return nil
	end
	local open = hover:find("(", start, true)
	local params, depth, current = {}, 0, ""
	for i = open + 1, #hover do
		local ch = hover:sub(i, i)
		if ch == "(" or ch == "<" or ch == "[" then
			depth = depth + 1
		elseif ch == "]" or ch == ">" then
			depth = depth - 1
		elseif ch == ")" then
			if depth == 0 then
				table.insert(params, current)
				break
			end
			depth = depth - 1
		end
		if ch == "," and depth == 0 then
			table.insert(params, current)
			current = ""
		else
			current = current .. ch
		end
	end
	local types = {}
	for _, param in ipairs(params) do
		param = vim.trim(param):gsub("^%[(.*)%]$", "%1") -- optional params are shown as [T x = default]
		param = param:gsub("%s*=.*$", "")
		for _, modifier in ipairs({ "this", "ref", "out", "in", "params", "scoped", "readonly" }) do
			param = param:gsub("^" .. modifier .. "%s+", "")
		end
		local ptype = param:match("^(.-)%s+[%w_@]+$")
		if ptype and ptype ~= "" then
			table.insert(types, ptype)
		end
	end
	return #types > 0 and types or nil
end

-- The signature starting at a quickfix item, joined across lines until the
-- closing parenthesis, so multi-line parameter lists can be matched.
local function signature_at(item)
	local text = item.text
	if text:find(")", 1, true) then
		return text
	end
	local ok, lines = pcall(vim.fn.readfile, item.filename, "", item.lnum + 15)
	if not ok then
		return text
	end
	return table.concat(vim.list_slice(lines, item.lnum), " ")
end

local function contains_type(text, t)
	local pattern = "%f[%w_]" .. vim.pesc(t)
	if t:match("[%w_]$") then
		pattern = pattern .. "%f[^%w_]"
	end
	return text:find(pattern) ~= nil
end

-- Roslyn ignores generic arguments for implementations, so gi on
-- IHandler<Cmd, X>.HandleAsync lists every handler. Keep only the ones whose
-- parameters match the concrete types shown in the hover at the cursor.
local function filter_by_signature(bufnr, win, items, done)
	local name = vim.fn.expand("<cword>")
	vim.lsp.buf_request_all(bufnr, "textDocument/hover", function(client)
		return vim.lsp.util.make_position_params(win, client.offset_encoding)
	end, function(results)
		local types
		for _, res in pairs(results) do
			local contents = res.result and res.result.contents
			local value = type(contents) == "table" and (contents.value or contents[1]) or contents
			if type(value) == "table" then
				value = value.value
			end
			types = type(value) == "string" and hover_param_types(value, name)
			if types then
				break
			end
		end
		if not types then
			return done(items)
		end
		local matching = vim.tbl_filter(function(item)
			local signature = signature_at(item)
			return vim.iter(types):all(function(t)
				return contains_type(signature, t)
			end)
		end, items)
		done(#matching > 0 and matching or items)
	end)
end

-- Like vim.lsp.buf.references/definition/implementation, but shows a spinner
-- notification while the server is working. A single result is jumped to
-- directly (unless always_list), multiple results go to the quickfix list.
-- opts.refine(bufnr, win, items, done) can narrow down multiple results.
local function lsp_locations(method, title, opts)
	opts = opts or {}
	return function()
		local bufnr = vim.api.nvim_get_current_buf()
		local win = vim.api.nvim_get_current_win()
		local stop = require("utility.spinner").start("Finding " .. title:lower() .. "...", { title = "LSP" })
		local encodings = {}

		local function show(items)
			stop()
			if #items == 0 then
				vim.notify("No " .. title:lower() .. " found", vim.log.levels.INFO)
			elseif #items == 1 and not opts.always_list then
				vim.lsp.util.show_document(items[1].user_data, encodings[items[1]], { focus = true })
			else
				vim.fn.setqflist({}, " ", { title = title, items = items })
				vim.cmd("botright copen")
			end
		end

		vim.lsp.buf_request_all(bufnr, method, function(client)
			local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
			if opts.context then
				params.context = opts.context
			end
			return params
		end, function(results)
			local items = {}
			for client_id, res in pairs(results) do
				local client = vim.lsp.get_client_by_id(client_id)
				local result = res.result
				if result and client then
					-- A single Location can be returned instead of a list
					if result.uri or result.targetUri then
						result = { result }
					end
					for _, item in ipairs(vim.lsp.util.locations_to_items(result, client.offset_encoding)) do
						encodings[item] = client.offset_encoding
						table.insert(items, item)
					end
				end
			end
			if #items > 1 and opts.refine then
				opts.refine(bufnr, win, items, show)
			else
				show(items)
			end
		end)
	end
end

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(args)
		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local map = function(modes, keys, func, desc)
			vim.keymap.set(modes, keys, func, { buffer = args.buf, desc = desc })
		end

		-- Navigation
		map("n", "gr", lsp_locations("textDocument/references", "References", { context = { includeDeclaration = true }, always_list = true }), "Show LSP references")
		map("n", "gd", lsp_locations("textDocument/definition", "Definitions"), "Go to LSP definition")
		map("n", "gi", lsp_locations("textDocument/implementation", "Implementations", { refine = filter_by_signature }), "Go to LSP implementation")
		map("n", "gD", vim.lsp.buf.declaration, "Go to LSP declaration")

		-- Diagnostics and documentations
		map("n", "<leader>lf", vim.diagnostic.open_float, "Show line diagnostics")
		map("n", "<leader>sh", vim.lsp.buf.signature_help, "Show signature help")
		map("i", "<c-k>", vim.lsp.buf.signature_help, "Show signature Help")

		-- LSP actions
		map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "See available code actions")
		map("n", "<leader>rn", vim.lsp.buf.rename, "[LSP] Rename")
		map("n", "<leader>rs", ":lsp restart<CR>", "Restart LSP")
		map("n", "<leader>rt", ":Roslyn target<CR>", "Select solution file with Roslyn LSP")

		-- workspace
		map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
		map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
		map("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, "List workspace folders")
	end,
})

-- Filetype overrides. Registered once via vim.filetype.add (resolved at buffer
-- creation) instead of BufRead/BufEnter autocmds, which re-ran the whole
-- FileType chain on every window switch.
vim.filetype.add({
	extension = {
		props = "xml",
		json = "jsonc",
	},
	pattern = {
		[".*%.component%.html"] = "htmlangular",
	},
})

-- .NET test runner
require("utility.test-runner").setup()
