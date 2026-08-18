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

			-- Highlight .razor with the `html` parser instead of `razor`.
			--
			-- The razor grammar can't parse real Blazor markup: `@* ... *@`
			-- comments inside an element, unclosed void elements (`<br>`) and an
			-- `@expr` on its own line before a tag (parsed as `context.Label < br`)
			-- all fail, and one failure turns the whole file's root into an ERROR
			-- node. It also has no nodes for tag names or attributes at all, so it
			-- delegates every tag to an html injection over each `(element)` with
			-- `injection.combined` -- which on a broken tree collapses into a
			-- single region built from ~60 overlapping, out-of-order ranges. The
			-- highlighter only parses the visible range, so which of those ranges
			-- have materialised (and therefore what colour a line gets) changes as
			-- you scroll.
			--
			-- The html parser handles the same file cleanly (root `document`,
			-- errors only inside `@code {}`), and Roslyn's semantic tokens sit on
			-- top at priority 125 for everything C#. Only tradeoff: `@* ... *@`
			-- comments lose their comment colour, since neither layer claims them.
			vim.treesitter.language.register("html", "razor")

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
