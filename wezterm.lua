local wezterm = require("wezterm")
local utf8 = require("utf8")
local os_check = require("os_check")
local config = wezterm.config_builder()

-- Add neovim to WezTerm PATH
if os_check.is_darwin() then
	config.set_environment_variables = {
		PATH = "/opt/homebrew/bin/:" .. os.getenv("PATH"),
	}
end

config.color_scheme = "Dracula (Official)"

-- Window settings
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.995

-- Window frame
config.window_frame = {
	font = wezterm.font("JetBrains Mono"),
	font_size = 14,
}

-- Tab settings
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = true
config.show_tab_index_in_tab_bar = true

config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 22

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local palette = config.resolved_palette.tab_bar
	local colors = {
		bg = palette.background,
		tab = tab.is_active and palette.active_tab.bg_color or palette.inactive_tab.bg_color,
		fg = tab.is_active and palette.active_tab.fg_color or palette.inactive_tab.fg_color,
	}

	return {
		{ Background = { Color = colors.bg } },
		{ Foreground = { Color = colors.tab } },
		{ Background = { Color = colors.tab } },
		{ Foreground = { Color = colors.fg } },
		{ Text = tab.tab_index + 1 .. ": " .. tab.active_pane.title },
		{ Background = { Color = colors.tab } },
		{ Foreground = { Color = colors.bg } },
	}
end)

-- Update status
local function segments_for_right_status(window)
	return {
		window:active_workspace(),
		wezterm.strftime("%a %b %-d %H:%M"),
		wezterm.hostname(),
	}
end

wezterm.on("update-status", function(window, _)
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
	local segments = segments_for_right_status(window)
	local color_scheme = window:effective_config().resolved_palette
	local bg = wezterm.color.parse(color_scheme.background)
	local fg = color_scheme.foreground

	local gradient_to = bg
	local gradient_from = gradient_to:lighten(0.2)

	local gradient = wezterm.color.gradient({
		orientation = "Horizontal",
		colors = { gradient_from, gradient_to },
	}, #segments)

	local elements = {}
	for i, seg in ipairs(segments) do
		local is_first = i == 1
		if is_first then
			table.insert(elements, { Background = { Color = "none" } })
		end
		table.insert(elements, { Foreground = { Color = gradient[i] } })
		table.insert(elements, { Text = SOLID_LEFT_ARROW })

		table.insert(elements, { Foreground = { Color = fg } })
		table.insert(elements, { Background = { Color = gradient[i] } })
		table.insert(elements, { Text = " " .. seg .. " " })
	end

	window:set_right_status(wezterm.format(elements))
end)

-- Keymaps

local function move_pane(key, direction)
	return {
		key = key,
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection(direction),
	}
end

local function resize_pane(key, direction)
	return {
		key = key,
		action = wezterm.action.AdjustPaneSize({ direction, 2 }),
	}
end

config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

local projects = require("projects")

config.keys = {
	-- MacOS-like behaviour on navigatin between words
	{
		key = "LeftArrow",
		mods = "OPT",
		action = wezterm.action.SendString("\x1bb"),
	},
	{
		key = "RightArrow",
		mods = "OPT",
		action = wezterm.action.SendString("\x1bf"),
	},
	-- Open WezTerm config file in nvim
	{
		key = ",",
		mods = "SUPER",
		action = wezterm.action.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { "nvim", wezterm.config_file },
		}),
	},
	-- Open nvim config folder in nvim (oil.nvim required)
	{
		key = ".",
		mods = "SUPER",
		action = wezterm.action.SpawnCommandInNewTab({
			cwd = wezterm.home_dir,
			args = { "nvim", "-c", "Oil", "~/.config/nvim" },
		}),
	},
	-- Splits
	{
		key = "'",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "5",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	-- CTRL + a
	{
		key = "a",
		mods = "LEADER",
		action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
	},

	-- Pane navigation
	move_pane("j", "Down"),
	move_pane("k", "Up"),
	move_pane("h", "Left"),
	move_pane("l", "Right"),

	-- Pane resizing
	{
		key = "r",
		mods = "LEADER",
		action = wezterm.action.ActivateKeyTable({
			name = "resize_panes",
			one_shot = false,
			timeout_milliseconds = 1000,
		}),
	},

	-- Workspaces
	{
		key = "p",
		mods = "LEADER",
		action = projects.choose_project(),
	},
	{
		key = "f",
		mods = "LEADER",
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
	},
}

config.key_tables = {
	resize_panes = {
		resize_pane("j", "Down"),
		resize_pane("k", "Up"),
		resize_pane("h", "Left"),
		resize_pane("l", "Right"),
	},
}

return config
