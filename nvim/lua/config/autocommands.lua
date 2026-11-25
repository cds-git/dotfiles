-- Like vim.lsp.buf.references/definition/implementation, but shows a spinner
-- notification while the server is working. A single result is jumped to
-- directly (unless always_list), multiple results go to the quickfix list.
local function lsp_locations(method, title, opts)
	opts = opts or {}
	return function()
		local bufnr = vim.api.nvim_get_current_buf()
		local win = vim.api.nvim_get_current_win()
		local stop = require("utility.spinner").start("Finding " .. title:lower() .. "...", { title = "LSP" })

		vim.lsp.buf_request_all(bufnr, method, function(client)
			local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
			if opts.context then
				params.context = opts.context
			end
			return params
		end, function(results)
			stop()
			local locations = {}
			local items = {}
			for client_id, res in pairs(results) do
				local client = vim.lsp.get_client_by_id(client_id)
				local result = res.result
				if result and client then
					-- A single Location can be returned instead of a list
					if result.uri or result.targetUri then
						result = { result }
					end
					for _, loc in ipairs(result) do
						table.insert(locations, { loc = loc, encoding = client.offset_encoding })
					end
					vim.list_extend(items, vim.lsp.util.locations_to_items(result, client.offset_encoding))
				end
			end
			if #items == 0 then
				vim.notify("No " .. title:lower() .. " found", vim.log.levels.INFO)
				return
			end
			if #locations == 1 and not opts.always_list then
				vim.lsp.util.show_document(locations[1].loc, locations[1].encoding, { focus = true })
				return
			end
			vim.fn.setqflist({}, " ", { title = title, items = items })
			vim.cmd("botright copen")
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
		map("n", "gi", lsp_locations("textDocument/implementation", "Implementations"), "Go to LSP implementation")
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
