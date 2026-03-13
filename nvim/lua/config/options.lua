vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Shows the effects of substitute etc. as you type
vim.opt.inccommand = "split"

-- Case-insensitive search
vim.opt.ignorecase = true

-- If given an uppercase, only display results with uppercase
vim.opt.smartcase = true

-- Show line numbers default
vim.opt.number = true

-- Show relative line numbers
vim.opt.relativenumber = true

-- Disable word wrap, enable temporarily with `:set wrap` when needed
vim.opt.wrap = false

-- Separate sign column (extra column for Git/LSP)
vim.opt.signcolumn = "yes"

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true -- indent using spaces instead of <Tab>

-- Always keep this amount of lines above and below the cursor
vim.opt.scrolloff = 5

-- Highlight current line
vim.opt.cursorline = true

-- Natural split directions
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Cursor shape configuration for different modes
-- n-v-c: block in normal, visual, command modes
-- i-ci-ve: vertical bar (25% width) in insert modes
-- r-cr: horizontal bar (20% height) in replace modes
-- o: horizontal bar (50% height) in operator-pending mode
-- Add blinking to all modes
vim.opt.guicursor = "n-v-c:block-blinkon300-blinkwait200-blinkoff300,i-ci-ve:ver25-blinkon300-blinkwait200-blinkoff300,r-cr:hor20,o:hor50"

vim.opt.termguicolors = true

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
-- https://neovim.io/doc/user/options.html
vim.opt.completeopt = "menuone,noselect"

-- Mode is shown in lualine, so we don't need it one line below
vim.opt.showmode = false

-- Rounded borders
vim.opt.winborder = "rounded"

-- Inline hints
vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = "󰠠 ",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
			[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
			[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
		},
	},
	virtual_text = false,
	virtual_lines = false,
})

-- Disable LSP log because it's slowing down Neovim
vim.lsp.set_log_level("OFF")

-- set no swap files
vim.opt.swapfile = false
vim.opt.backup = false

-- And use undodir instead
-- Allow undo-ing even after save file
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.undofile = true

-- filenames
vim.opt.fileformat = "unix"
vim.opt.fileformats = "unix,dos"
vim.opt.fileencoding = "utf-8"

vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"
