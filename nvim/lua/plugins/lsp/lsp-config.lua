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
						kubernetes = {
							"*.yaml",
							-- Helm
							"!**/values.yaml",
							"!**/values-*.yaml",
							"!**/values/*.yaml",
							"!**/value-files/**/*.yaml",
							"!**/templates/**/*.yaml",
							"!Chart.yaml",
							"!chart.yaml",
							-- Flux GitOps (own CRD schemas below)
							"!**/hr-*.yaml",
							"!**/patch-image-tags.yaml",
							"!**/image-automations.yaml",
							"!**/image-update-automations.yaml",
							"!**/flux-system/**/*.yaml",
							-- Other tools
							"!kustomization.yaml",
							"!helmfile.yaml",
							"!docker-compose*.yaml",
							"!.github/**/*.yaml",
						},
						["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
						["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
						["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
						["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
						["http://json.schemastore.org/compose"] = "docker-compose*.{yml,yaml}",
						["http://json.schemastore.org/helmfile"] = "helmfile.{yml,yaml}",

						-- Flux CRDs (datreeio/CRDs-catalog).
						-- Only mapped here for single-kind files; mixed-kind multi-doc files
						-- (e.g. image-automations.yaml) must use per-doc modelines instead.
						["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/helm.toolkit.fluxcd.io/helmrelease_v2.json"] = {
							"**/hr-*.yaml",
							"**/patch-image-tags.yaml",
						},
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

		-- Mason exposes vtsls as a symlink (mason/bin/vtsls). Its npm `.bin` launcher
		-- is an sh shim that resolves its own location from $0 *without* dereferencing
		-- the symlink, so launching via the symlink looks for `mason/@vtsls/...` and
		-- crashes (MODULE_NOT_FOUND) -> vtsls never attaches -> no go-to-definition.
		-- Point the cmd at the resolved real path so the shim resolves correctly.
		vim.lsp.config("vtsls", {
			cmd = { vim.uv.fs_realpath(vim.fn.exepath("vtsls")) or "vtsls", "--stdio" },
		})

		-- Only attach angularls inside actual Angular/Nx workspaces. Otherwise it
		-- attaches to every TS/HTML buffer (root_markers fall back to single-file
		-- mode in nvim 0.11) and competes with vtsls without providing definitions.
		vim.lsp.config("angularls", {
			root_dir = function(bufnr, on_dir)
				local fname = vim.api.nvim_buf_get_name(bufnr)
				local root = vim.fs.root(fname, { "angular.json", "nx.json" })
				if root then
					on_dir(root)
				end
			end,
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
}
