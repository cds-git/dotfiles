return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			markdown = { "prettierd" },
			sh = { "shfmt" },
			javascript = { "eslint_d", "prettierd" },
			typescript = { "eslint_d", "prettierd" },
			angular = { "prettierd" },
			yaml = { "prettierd" },
			json = { "prettierd" },
			html = { "prettierd" },
			scss = { "prettierd" },
			css = { "prettierd" },
			xml = { "xmlformatter", "xml_keep_declared_encoding" },
			-- snacks.bigfile sets filetype to "bigfile", hiding the real one.
			-- Resolve the real filetype and use its formatters instead.
			bigfile = function(bufnr)
				local ft = vim.filetype.match({ buf = bufnr })
				if not ft or ft == "bigfile" then
					return {}
				end
				local formatters = require("conform").formatters_by_ft[ft]
				if type(formatters) == "function" then
					return formatters(bufnr)
				end
				return formatters or {}
			end,
		},
		-- format_on_save = {
		-- 	timeout_ms = 1000,
		-- 	lsp_fallback = true,
		-- },
		formatters = {
			-- xmlformat honours the encoding in the XML declaration for its
			-- output, so a utf-16 file comes back as utf-16 bytes and garbles
			-- the buffer. Force utf-8 text; Neovim re-encodes on write.
			xmlformatter = {
				args = { "--outencoding", "utf-8", "-" },
			},
			-- --outencoding rewrites the declaration to UTF-8, which then lies
			-- about the bytes on disk. Put the original encoding back.
			xml_keep_declared_encoding = {
				format = function(_, ctx, lines, callback)
					local first = vim.api.nvim_buf_get_lines(ctx.buf, 0, 1, false)[1] or ""
					local original = first:match('^<%?xml[^?]-encoding="([^"]+)"')
					if original and lines[1] then
						lines[1] = lines[1]:gsub('^(<%?xml[^?]-encoding=")[^"]+(")', "%1" .. original .. "%2", 1)
					end
					callback(nil, lines)
				end,
			},
		},
	},
	config = function(_, opts)
		local conform = require("conform")
		conform.setup(opts)

		vim.keymap.set("n", "<leader>fm", function()
			conform.format({ async = true, lsp_format = "fallback" })
		end, { desc = "Format file" })
	end,
}
