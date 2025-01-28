-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

config.color_scheme = "catppuccin-mocha"

config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 13.2

config.window_padding = { bottom = 0 }

config.front_end = "OpenGL"
config.max_fps = 144
config.default_cursor_style = "BlinkingBlock"
config.animation_fps = 1
config.cursor_blink_rate = 500
config.prefer_egl = true
config.term = "xterm-256color" -- Set the terminal type

-- tabs
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- config.window_decorations = "NONE | RESIZE"

config.default_prog = { "powershell.exe", "-NoLogo" }

config.keys = {
	-- paste from the clipboard
	{ key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	-- paste from the primary selection
	{ key = "V", mods = "CTRL", action = act.PasteFrom("PrimarySelection") },
    -- copy to clipboad
	{ key = "C", mods = "CTRL", action = wezterm.action.CopyTo("ClipboardAndPrimarySelection") },
}
-- and finally, return the configuration to wezterm
return config
