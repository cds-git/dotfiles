vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Set highlight on search
vim.opt.hlsearch = true

-- Incremental search, helps to find 'regex' for search
vim.opt.incsearch = true

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

-- Separate sign colum (extra column for Git/LSP)
vim.wo.signcolumn = "yes"

-- Create splits vertically by default
-- vim.opt.diffopt = "vertical"

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true -- indent using spaces instead of <Tab>
--vim.opt.breakindent = true
-- vim.opt.autoindent = true
-- vim.opt.smartindent = true
-- vim.opt.cindent = true

-- highlight columns
-- vim.opt.colorcolumn = "80,120"

-- Sync clipboard between OS and Neovim.
-- Remove this option if you want your OS clipboard to remain independent.
--vim.opt.clipboard = 'unnamedplus'

-- Always keep this amount of lines above and below the cursor
vim.opt.scrolloff = 5

-- Highlight current line
vim.opt.cursorline = true

-- Cursor shape configuration for different modes
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"

-- Blink cursor in normal mode
--vim.opt.guicursor = 'n:blinkon300-blinkwait200-blinkoff300'

vim.opt.termguicolors = true

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
-- https://neovim.io/doc/user/options.html
vim.opt.completeopt = "menuone,noselect"

-- Split windows appear below, not above
-- vim.opt.splitbelow = true

-- Split windows appear to the right instead of left
-- vim.opt.splitright = true

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
	-- virtual_lines = {
	--     current_line = true,
	-- },
})

-- Disable log because it's slowing down Neovim
vim.lsp.log_levels = "OFF"

-- TODO: Find out if settings below are needed

-- set no swap files
vim.opt.swapfile = false
vim.opt.backup = false

-- And use undodir instead
-- Allow undo-ing even after save file
vim.opt.undodir = vim.fn.stdpath("config") .. "/.undo"
vim.opt.undofile = true

-- Hide 'No write since last change' error on switching buffers Keeps buffer open in the background.
vim.opt.hidden = true

vim.opt.backspace = "indent,eol,start"

-- filenames
vim.opt.fileformat = "unix"
vim.opt.fileformats = "unix,dos"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"
