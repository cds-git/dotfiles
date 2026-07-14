-- Enable Neovim's Lua module/bytecode cache before anything else loads.
vim.loader.enable()

require("config.options")

require("config.keymaps")

require("config.lazy")

require("config.autocommands")

