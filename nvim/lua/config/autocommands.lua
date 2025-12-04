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
		map("n", "<leader>rs", ":LspRestart<CR>", "Restart LSP")
		map("n", "<leader>rr", ":Roslyn restart<CR>", "Restart Roslyn LSP")
		map("n", "<leader>rt", ":Roslyn target<CR>", "Select solution file with Roslyn LSP")

		-- workspace
		map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
		map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
		map("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, "List workspace folders")

		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method("textDocument/signatureHelp") then
			local lsp_overloads_ok, lsp_overloads = pcall(require, "lsp-overloads")
			if lsp_overloads_ok then
				lsp_overloads.setup(client, {
					-- UI options are mostly the same as those passed to vim.lsp.util.open_floating_preview
					ui = {
						border = "rounded", -- The border to use for the signature popup window. Accepts same border values as |nvim_open_win()|.
						floating_window_above_cur_line = true, -- Attempt to float the popup above the cursor position
						-- (note, if the height of the float would be greater than the space left above the cursor, it will default
						-- to placing the float below the cursor. The max_height option allows for finer tuning of this)
					},
					keymaps = {
						next_signature = "<C-j>",
						previous_signature = "<C-k>",
						next_parameter = "<C-l>",
						previous_parameter = "<C-h>",
						close_signature = "<A-s>",
					},
					display_automatically = false, -- Uses trigger characters to automatically display the signature overloads when typing a method signature
				})

				vim.keymap.set(
					"n",
					"<leader>sh",
					"<cmd>LspOverloadsSignature<CR>",
					{ buffer = args.buf, desc = "Show signature help", remap = true }
				)
				vim.keymap.set(
					"i",
					"<c-k>",
					"<cmd>LspOverloadsSignature<CR>",
					{ buffer = args.buf, desc = "Show signature help", remap = true }
				)
			end
		end
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
		vim.bo.filetype = "angular"
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufEnter" }, {
	pattern = { "*.json" },
	callback = function()
		vim.bo.filetype = "jsonc"
	end,
})
