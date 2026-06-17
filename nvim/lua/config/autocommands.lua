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
		map("n", "gr", vim.lsp.buf.references, "Show LSP references")
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

vim.api.nvim_create_autocmd({ "BufRead", "BufEnter" }, {
	pattern = { "*.props" },
	callback = function()
		vim.bo.filetype = "xml"
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufEnter" }, {
	pattern = { "*.component.html" },
	callback = function()
		vim.bo.filetype = "htmlangular"
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufEnter" }, {
	pattern = { "*.json" },
	callback = function()
		vim.bo.filetype = "jsonc"
	end,
})

-- .NET test runner
require("utility.test-runner").setup()
