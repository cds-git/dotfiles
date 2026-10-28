-- Remove default LSP keymaps so our own `gr` fires without waiting for gr* chords
vim.keymap.del("n", "grn")
vim.keymap.del({ "n", "x" }, "gra")
vim.keymap.del("n", "grr")
vim.keymap.del("n", "gri")
vim.keymap.del("n", "grt")
vim.keymap.del("n", "grx")
vim.keymap.del("n", "gO")
vim.keymap.del("i", "<C-s>")

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General clear highlights" })

-- File mappings
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save File" })

-- Move Lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Copy and paste clipboard
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to clipboard" })
map("n", "<leader>Y", "<cmd>%y+<CR>", { desc = "Copy whole file to clipboard" })

map("n", "<leader>q", "<C-w>q", { desc = "[Window] Quit" })

-- Cycle spell checking between English, Danish and both. Neovim can't fetch the Danish
-- dictionary itself (its downloader needs netrw, which is disabled), so get it here.
local spell_langs = { "en", "da", "en,da" }
map("n", "<leader>ua", function()
	local spell_dir = vim.fn.stdpath("data") .. "/site/spell"
	local da_file = spell_dir .. "/da.utf-8.spl"
	if vim.fn.filereadable(da_file) == 0 and vim.fn.globpath(vim.o.runtimepath, "spell/da.utf-8.spl") == "" then
		vim.fn.mkdir(spell_dir, "p")
		vim.notify("Downloading Danish spell file...")
		vim.fn.system({ "curl", "-fsSLo", da_file, "https://ftp.nluug.nl/pub/vim/runtime/spell/da.utf-8.spl" })
		if vim.v.shell_error ~= 0 then
			vim.notify("Could not download the Danish spell file", vim.log.levels.ERROR)
			return
		end
	end
	local current = vim.bo.spelllang
	local next_lang = spell_langs[1]
	for i, lang in ipairs(spell_langs) do
		if lang == current then
			next_lang = spell_langs[i % #spell_langs + 1]
		end
	end
	vim.opt_local.spelllang = next_lang
	vim.opt_local.spell = true
	vim.notify("Spell language: " .. next_lang)
end, { desc = "Cycle spell language (en, da, en+da)" })

-- Built-in undo tree, loaded the first time it's opened
map("n", "<leader>uu", function()
	vim.cmd.packadd("nvim.undotree")
	vim.cmd("Undotree")
end, { desc = "Toggle Undotree" })

-- Window navigations
map("n", "<C-h>", "<C-w>h", { desc = "[Window] Switch left" })
map("n", "<C-j>", "<C-w>j", { desc = "[Window] Switch down" })
map("n", "<C-k>", "<C-w>k", { desc = "[Window] Switch up" })
map("n", "<C-l>", "<C-w>l", { desc = "[Window] Switch right" })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- .NET Test Runner
map("n", "<leader>tt", "<cmd>DotnetTestRunner<cr>", { desc = "[Test] Toggle test runner" })
map("n", "<leader>tr", "<cmd>DotnetTestRun<cr>", { desc = "[Test] Run nearest test" })
map("n", "<leader>td", "<cmd>DotnetTestDebug<cr>", { desc = "[Test] Debug nearest test" })
map("n", "<leader>tf", "<cmd>DotnetTestFocus<cr>", { desc = "[Test] Focus nearest test in runner" })
map("n", "<leader>tD", "<cmd>DotnetTestDiscover<cr>", { desc = "[Test] Discover tests" })

