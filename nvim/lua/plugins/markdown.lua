return {
	{
		-- In-buffer markdown rendering (headings, code blocks, tables, checkboxes,
		-- callouts, etc). Renders in normal mode and reveals raw text on the line
		-- the cursor is on / in insert mode. No browser needed -- works in the
		-- terminal, unlike the old browser-based markdown-preview.nvim.
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		ft = { "markdown" },
		opts = {
			-- in-process LSP that blink picks up: completes callouts (`> [!`) and checkbox states
			completions = { lsp = { enabled = true } },
			heading = {
				-- the gutter is for git/diagnostics; the heading icon already marks the level
				sign = false,
				-- background only as wide as the heading text, like Obsidian
				width = "block",
				left_pad = 1,
				right_pad = 2,
			},
			code = {
				sign = false,
				width = "block",
				right_pad = 2,
			},
			checkbox = {
				custom = {
					-- Obsidian's common extra states
					important = { raw = "[!]", rendered = "󰀦 ", highlight = "DiagnosticWarn" },
					cancelled = { raw = "[~]", rendered = "󰰱 ", highlight = "Comment", scope_highlight = "@markup.strikethrough" },
				},
			},
		},
		keys = {
			{ "<leader>um", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown Render" },
		},
	},
	{
		-- Lists that continue on <CR>/o, renumber themselves and toggle checkboxes
		"bullets-vim/bullets.vim",
		ft = { "markdown", "text", "gitcommit" },
		init = function()
			vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit" }
			-- `[ ]` / `[x]` exactly as Obsidian writes them (the default checks with `X`)
			vim.g.bullets_checkbox_markers = " x"
			-- no roman numerals or letters when indenting; nested items become `-`
			vim.g.bullets_outline_levels = { "num", "std-" }
			-- the defaults put the checkbox toggle on <leader>x, which deletes the buffer
			vim.g.bullets_set_mappings = 0
			vim.g.bullets_custom_mappings = {
				{ "imap", "<CR>", "<Plug>(bullets-newline)" },
				{ "nmap", "o", "<Plug>(bullets-newline)" },
				{ "nmap", "<CR>", "<Plug>(bullets-toggle-checkbox)" },
				{ "nmap", "gN", "<Plug>(bullets-renumber)" },
				{ "vmap", "gN", "<Plug>(bullets-renumber)" },
				{ "imap", "<C-t>", "<Plug>(bullets-demote)" },
				{ "imap", "<C-d>", "<Plug>(bullets-promote)" },
				{ "nmap", ">>", "<Plug>(bullets-demote)" },
				{ "nmap", "<<", "<Plug>(bullets-promote)" },
				{ "vmap", ">", "<Plug>(bullets-demote)" },
				{ "vmap", "<", "<Plug>(bullets-promote)" },
			}
		end,
	},
}
