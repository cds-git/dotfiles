return {
	"lewis6991/gitsigns.nvim",
	opts = {
		current_line_blame_opts = {
			virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
			delay = 0,
		},
		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")

			-- hunks
			vim.keymap.set("n", "]h", gitsigns.next_hunk, { buffer = bufnr, desc = "[Gitsigns] Next Hunk" })
			vim.keymap.set("n", "[h", gitsigns.prev_hunk, { buffer = bufnr, desc = "[Gitsigns] Prev Hunk" })
			vim.keymap.set("n", "<leader>gp", gitsigns.preview_hunk, { desc = "[Gitsigns] Preview git hunk" })

			-- blame
			vim.keymap.set("n", "<leader>gB", function()
				gitsigns.blame_line({ full = true })
			end, { buffer = bufnr, desc = "[Gitsigns] Blame details" })

			vim.keymap.set("n", "<leader>gt", function()
				gitsigns.toggle_current_line_blame()
			end, { buffer = bufnr, desc = "[Gitsigns] Toggle blame line" })

			-- diff
			vim.keymap.set("n", "<leader>gD", gitsigns.diffthis, { desc = "[Gitsigns] Diff this" })

			-- stage / reset hunks (visual mode stages just the selected lines)
			vim.keymap.set({ "n", "v" }, "<leader>hs", "<cmd>Gitsigns stage_hunk<CR>", { buffer = bufnr, desc = "[Gitsigns] Stage hunk" })
			vim.keymap.set({ "n", "v" }, "<leader>hr", "<cmd>Gitsigns reset_hunk<CR>", { buffer = bufnr, desc = "[Gitsigns] Reset hunk" })
			vim.keymap.set("n", "<leader>hS", gitsigns.stage_buffer, { buffer = bufnr, desc = "[Gitsigns] Stage buffer" })
			vim.keymap.set("n", "<leader>hR", gitsigns.reset_buffer, { buffer = bufnr, desc = "[Gitsigns] Reset buffer" })
			vim.keymap.set("n", "<leader>hu", gitsigns.undo_stage_hunk, { buffer = bufnr, desc = "[Gitsigns] Undo stage hunk" })
		end,
	},
}
