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
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true

-- config.window_decorations = "NONE | RESIZE"

-- config.default_domain = 'WSL:Ubuntu'
config.default_prog = { "powershell.exe", "-NoLogo" }
-- config.default_prog = { "wsl.exe", "-d", "Ubuntu" }

config.keys = {
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)

				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
	-- Ctrl+V: paste from clipboard
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
	-- Create a new tab in the same domain as the current pane.
	-- This is usually what you want.
	-- {
	--     key = 't',
	--     mods = 'SHIFT|ALT',
	--     action = act.SpawnTab 'CurrentPaneDomain',
	-- },
	-- Create a new tab in the default domain
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("DefaultDomain") },
	-- Create a tab in a named domain
	{
		key = "t",
		mods = "SHIFT|ALT",
		action = act.SpawnTab({
			DomainName = "WSL:Ubuntu",
		}),
	},
}
-- and finally, return the configuration to wezterm
return config
