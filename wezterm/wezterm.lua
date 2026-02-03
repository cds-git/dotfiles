-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Visual
config.color_scheme = "catppuccin-mocha"
-- Use FiraCode Nerd Font, fall back to bundled JetBrains Mono
-- WezTerm will automatically append Nerd Font Symbols and Noto Color Emoji
config.font = wezterm.font_with_fallback({
	"FiraCode Nerd Font",
	"JetBrains Mono",
})
config.font_size = 13.2
config.window_padding = { bottom = 0 }

-- Performance
config.front_end = "OpenGL" -- Try WebGpu first, fallback to OpenGL if issues
config.max_fps = 144
config.animation_fps = 1
config.cursor_blink_rate = 500
config.prefer_egl = true

-- Terminal type
config.term = "xterm-256color"

-- Mouse behavior - helps prevent gibberish input issues
config.alternate_buffer_wheel_scroll_speed = 1
config.bypass_mouse_reporting_modifiers = "SHIFT" -- Hold Shift to bypass app mouse handling

-- Cursor
config.default_cursor_style = "BlinkingBlock"

-- Tabs
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false

-- Launch menu for easy shell switching (primarily for Windows)
-- On Linux/Mac, this will show the system shells
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.default_prog = { "powershell.exe", "-NoLogo" }
	config.launch_menu = {
		{
			label = "PowerShell",
			args = { "powershell.exe", "-NoLogo" },
		},
		{
			label = "WSL",
			args = { "wsl.exe", "--cd", "~" },
		},
		{
			label = "WSL Ubuntu",
			args = { "wsl.exe", "-d", "Ubuntu", "--cd", "~" },
		},
		{
			label = "Command Prompt",
			args = { "cmd.exe" },
		},
	}
end

-- Keybindings
config.keys = {
	-- COPY/PASTE
	-- Copy with Ctrl+Shift+C
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL|SHIFT" }), pane)
			end
		end),
	},

	-- Paste with Ctrl+Shift+V
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = act.PasteFrom("Clipboard"),
	},

	-- SHELL SWITCHING
	-- Open launch menu to select shell
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = act.ShowLauncher,
	},

	-- SCROLLBACK / COPY MODE
	-- Enter copy/search mode with vim keybinds
	{
		key = "Space",
		mods = "CTRL|SHIFT",
		action = act.ActivateCopyMode,
	},

	-- Quick search
	{
		key = "f",
		mods = "CTRL|SHIFT",
		action = act.Search({ CaseSensitiveString = "" }),
	},

	-- Quick scroll shortcuts (without entering copy mode)
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = act.ScrollByLine(-1),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = act.ScrollByLine(1),
	},
	{
		key = "u",
		mods = "CTRL|SHIFT",
		action = act.ScrollByPage(-0.5),
	},
	{
		key = "d",
		mods = "CTRL|SHIFT",
		action = act.ScrollByPage(0.5),
	},

	-- Alt+Arrow scroll shortcuts (consistent with tmux navigation)
	{
		key = "UpArrow",
		mods = "ALT",
		action = act.ScrollByLine(-1),
	},
	{
		key = "DownArrow",
		mods = "ALT",
		action = act.ScrollByLine(1),
	},

	-- TAB MANAGEMENT
	-- Create new tab with default shell
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },

	-- Navigate tabs
	{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },

	-- Close tab
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },

	-- Jump to specific tabs
	{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = act.ActivateTab(4) },
	{ key = "6", mods = "ALT", action = act.ActivateTab(5) },
	{ key = "7", mods = "ALT", action = act.ActivateTab(6) },
	{ key = "8", mods = "ALT", action = act.ActivateTab(7) },
	{ key = "9", mods = "ALT", action = act.ActivateTab(8) },

	-- TERMINAL RESET
	-- Reset terminal to fix gibberish mouse input (Ctrl+Alt+R)
	{
		key = "r",
		mods = "CTRL|ALT",
		action = act.SendString("\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l\x0c"),
	},
}

-- Windows-specific quick spawn keybinds
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	table.insert(
		config.keys,
		{
			key = "p",
			mods = "CTRL|SHIFT|ALT",
			action = act.SpawnCommandInNewTab({
				args = { "powershell.exe", "-NoLogo" },
			}),
		}
	)
	table.insert(
		config.keys,
		{
			key = "l",
			mods = "CTRL|SHIFT|ALT",
			action = act.SpawnCommandInNewTab({
				args = { "wsl.exe", "--cd", "~"  },
			}),
		}
	)
end

-- Configure copy mode to use vi-style keybinds
config.key_tables = {
	copy_mode = {
		-- Vi motions
		{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },

		-- Arrow key navigation
		{ key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },

		-- Word movement
		{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
		{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
		{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },

		-- Line movement
		{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
		{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
		{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },

		-- Page movement
		{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
		{ key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
		{ key = "u", mods = "CTRL", action = act.CopyMode("PageUp") },
		{ key = "d", mods = "CTRL", action = act.CopyMode("PageDown") },
		{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
		{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },

		-- Selection
		{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },

		-- Copy
		{
			key = "y",
			mods = "NONE",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "Close" },
			}),
		},

		-- Search
		{ key = "/", mods = "NONE", action = act.Search("CurrentSelectionOrEmptyString") },
		{ key = "n", mods = "NONE", action = act.CopyMode("NextMatch") },
		{ key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") },

		-- Exit
		{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
	},

	search_mode = {
		{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "Enter", mods = "NONE", action = act.CopyMode("PriorMatch") },
		{ key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
		{ key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
		{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
		{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
	},
}

-- Return the configuration to wezterm
return config
