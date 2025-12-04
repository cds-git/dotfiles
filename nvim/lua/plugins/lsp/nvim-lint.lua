return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			json = { "jsonlint" },
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
				local client = get_clients({ bufnr = 0 })[1] or {}
				lint.try_lint(nil, { cwd = client.root_dir })
				-- lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>lcf", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
