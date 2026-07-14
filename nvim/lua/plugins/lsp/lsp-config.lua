return {
	"neovim/nvim-lspconfig",
	config = function()
		-- Improve LSP hover / signature floats. Some servers (Roslyn) emit XML-doc
		-- text as markdown with things Neovim's renderer shows raw:
		--   * cap the width so long doc lines wrap instead of running off-screen
		--   * strip markdown backslash-escapes (e.g. `\.`, `\-`, `\<`)
		--   * decode HTML entities (e.g. `&nbsp;` around <c> inline code, `&lt;`)
		-- Named HTML entities -> Unicode code point. nbsp maps to a normal space
		-- (32) rather than U+00A0 to avoid non-breaking-space wrapping quirks.
		local html_entities = {
			nbsp = 32,
			amp = 38,
			lt = 60,
			gt = 62,
			quot = 34,
			apos = 39,
			copy = 169,
			reg = 174,
			trade = 8482,
			mdash = 8212,
			ndash = 8211,
			hellip = 8230,
			lsquo = 8216,
			rsquo = 8217,
			ldquo = 8220,
			rdquo = 8221,
			bull = 8226,
			middot = 183,
			deg = 176,
			plusmn = 177,
			times = 215,
			divide = 247,
			sect = 167,
			para = 182,
			laquo = 171,
			raquo = 187,
			dagger = 8224,
			larr = 8592,
			rarr = 8594,
			uarr = 8593,
			darr = 8595,
			le = 8804,
			ge = 8805,
			ne = 8800,
			frac12 = 189,
			frac14 = 188,
			frac34 = 190,
			euro = 8364,
			pound = 163,
			cent = 162,
			yen = 165,
		}

		local function decode_entities(s)
			s = s:gsub("&(%w+);", function(name)
				local cp = html_entities[name]
				return cp and vim.fn.nr2char(cp, true) or ("&" .. name .. ";")
			end)
			s = s:gsub("&#(%d+);", function(n)
				return vim.fn.nr2char(tonumber(n), true)
			end)
			s = s:gsub("&#[xX](%x+);", function(n)
				return vim.fn.nr2char(tonumber(n, 16), true)
			end)
			return s
		end

		local orig_open_floating_preview = vim.lsp.util.open_floating_preview
		function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
			opts = opts or {}
			opts.max_width = opts.max_width or 100
			opts.max_height = opts.max_height or 30
			opts.wrap = opts.wrap ~= false

			if syntax == "markdown" or syntax == nil then
				local in_code_fence = false
				for i, line in ipairs(contents) do
					if line:match("^%s*```") then
						in_code_fence = not in_code_fence
					elseif not in_code_fence then
						-- drop a backslash that escapes an ASCII punctuation char,
						-- then turn HTML entities back into their characters
						contents[i] = decode_entities(line:gsub("\\(%p)", "%1"))
					end
				end
			end

			return orig_open_floating_preview(contents, syntax, opts, ...)
		end

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
