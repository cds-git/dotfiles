return {
	{
		"nvim-treesitter/nvim-treesitter",
		-- The legacy `master` branch is frozen and does NOT support Neovim 0.12+.
		-- The `main` branch is the supported rewrite for 0.12.
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup()

			-- The `main` branch dropped the old `auto_install`/`ensure_installed`
			-- options, so we replicate auto-install: when a buffer's filetype has
			-- a parser available upstream, install it on demand (once), then enable
			-- highlighting + treesitter-based indentation for that buffer. No need
			-- to maintain a hardcoded parser list.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("nvim_treesitter_start", { clear = true }),
				callback = function(args)
					local buf = args.buf
					local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
					if not lang then
						return
					end

					local nts = require("nvim-treesitter")

					local function start()
						if not vim.api.nvim_buf_is_valid(buf) then
							return
						end
						-- Only start if a parser is actually present for this language.
						if not pcall(vim.treesitter.start, buf, lang) then
							return
						end
						-- Treesitter-based indentation (experimental upstream).
						vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end

					if vim.tbl_contains(nts.get_installed(), lang) then
						start()
					elseif vim.tbl_contains(nts.get_available(), lang) then
						-- Async download/compile; enable highlighting once ready.
						nts.install(lang):await(vim.schedule_wrap(start))
					end
				end,
			})
		end,
	},
}
