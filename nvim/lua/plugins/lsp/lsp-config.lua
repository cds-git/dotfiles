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

		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					schemas = {
						kubernetes = "*.yaml",
						["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
						["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
						["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
						["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
						["http://json.schemastore.org/compose"] = "docker-compose*.{yml,yaml}",
						["http://json.schemastore.org/helmfile"] = "helmfile.{yml,yaml}",
					},
					schemaStore = {
						enable = true,
						url = "https://www.schemastore.org/api/json/catalog.json",
					},
					validate = true,
					completion = true,
					hover = true,
				},
			},
		})

		vim.lsp.config("helm_ls", {
			settings = {
				["helm-ls"] = {
					yamlls = {
						enabled = true,
						path = "yaml-language-server",
					},
				},
			},
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
