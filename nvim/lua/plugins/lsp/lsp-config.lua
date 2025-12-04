return {
	"neovim/nvim-lspconfig",
	config = function()
		vim.lsp.config("*", {
			capabilities = {
				textDocument = {
					semanticTokens = {
						multilineTokenSupport = true,
					},
				},
			},
			-- root_markers = { ".git" },
		})
		vim.lsp.enable({
			"lua_ls",
			"marksman",
			"angularls",
			"html",
			"cssls",
			"vtsls",
			"jsonls",
			"yamlls",
			"bashls",
			"dockerls",
			"docker_compose_language_service",
			"helm_ls",
			-- "roslyn_ls", -- enable when roslyn.nvim is no longer needed
		})
	end,
	dependencies = {
		{ "Issafalcon/lsp-overloads.nvim", event = "BufReadPre" },
	},
}
