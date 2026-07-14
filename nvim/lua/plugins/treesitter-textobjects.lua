-- Treesitter-based text objects: select/move/swap by function, class, parameter.
-- MUST track nvim-treesitter's `main` branch (the old `master` module API is
-- incompatible with the main-branch rewrite we use in treesitter.lua).
return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true, -- jump forward to the textobject like targets.vim
				selection_modes = { ["@parameter.outer"] = "v" },
			},
			move = { set_jumps = true }, -- add movements to the jumplist
		})

		local select = require("nvim-treesitter-textobjects.select")
		local move = require("nvim-treesitter-textobjects.move")
		local swap = require("nvim-treesitter-textobjects.swap")

		-- Select (visual / operator-pending): af=a function, if=inner function,
		-- ac/ic=class, aa/ia=argument. Compose with d/c/y/v (e.g. `cif`, `vac`).
		local selects = {
			["af"] = "@function.outer",
			["if"] = "@function.inner",
			["ac"] = "@class.outer",
			["ic"] = "@class.inner",
			["aa"] = "@parameter.outer",
			["ia"] = "@parameter.inner",
		}
		for lhs, obj in pairs(selects) do
			vim.keymap.set({ "x", "o" }, lhs, function()
				select.select_textobject(obj, "textobjects")
			end, { desc = "Select " .. obj })
		end

		-- Move between functions (start with ]f/[f, end with ]F/[F). Class motion
		-- on ]c/[c is intentionally omitted -- it would shadow diff-mode ]c/[c.
		vim.keymap.set({ "n", "x", "o" }, "]f", function()
			move.goto_next_start("@function.outer", "textobjects")
		end, { desc = "Next function start" })
		vim.keymap.set({ "n", "x", "o" }, "[f", function()
			move.goto_previous_start("@function.outer", "textobjects")
		end, { desc = "Prev function start" })
		vim.keymap.set({ "n", "x", "o" }, "]F", function()
			move.goto_next_end("@function.outer", "textobjects")
		end, { desc = "Next function end" })
		vim.keymap.set({ "n", "x", "o" }, "[F", function()
			move.goto_previous_end("@function.outer", "textobjects")
		end, { desc = "Prev function end" })

		-- Swap the parameter under the cursor with the next / previous one.
		vim.keymap.set("n", "]a", function()
			swap.swap_next("@parameter.inner")
		end, { desc = "Swap parameter with next" })
		vim.keymap.set("n", "[a", function()
			swap.swap_previous("@parameter.inner")
		end, { desc = "Swap parameter with previous" })
	end,
}
