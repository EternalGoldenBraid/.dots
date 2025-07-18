-- ~/.config/wezterm/wezterm.lua

local wezterm = require 'wezterm'
local config = {}

-- General options
config.enable_tab_bar = true
config.audible_bell = 'Disabled'

-- Font (set your preferred font here)
config.font = wezterm.font_with_fallback {
  'JetBrains Mono',
  'FiraCode Nerd Font',
}
config.font_size = 11.0

-- Load platform-specific config
local ok, platform_config = pcall(require, 'platform')
if ok then
  for k, v in pairs(platform_config) do
    config[k] = v
  end
end
if not ok then
  wezterm.log_error("require('platform') failed: " .. tostring(platform_config))
end

-- Load keybindings
local ok_keys, key_config = pcall(require, 'keys')
if ok_keys and key_config.keys then
  config.keys = key_config.keys
end
if not ok_keys then
  print("Couldn't load keys: " .. tostring(key_config))
end

-- Colorscheme manually defined
config.colors = {
  foreground = "#c8d3f5",
  background = "#222436",
  cursor_bg = "#c8d3f5",
  cursor_border = "#c8d3f5",
  cursor_fg = "#222436",
  selection_bg = "#2d3f76",
  selection_fg = "#c8d3f5",
  ansi = {
    "#1b1d2b", "#ff757f", "#c3e88d", "#ffc777",
    "#82aaff", "#c099ff", "#86e1fc", "#828bb8",
  },
  brights = {
    "#444a73", "#ff757f", "#c3e88d", "#ffc777",
    "#82aaff", "#c099ff", "#86e1fc", "#c8d3f5",
  },
  indexed = {
    [16] = "#ff966c",
    [17] = "#c53b53",
  },
  tab_bar = {
    background = "#1b1d2b",
    active_tab = {
      bg_color = "#82aaff",
      fg_color = "#1e2030",
    },
    inactive_tab = {
      bg_color = "#2f334d",
      fg_color = "#545c7e",
    },
  },
}

-- Window border colors
config.window_frame = {
  active_titlebar_bg = "#82aaff",
  inactive_titlebar_bg = "#2f334d",
  active_titlebar_fg = "#1e2030",
  inactive_titlebar_fg = "#545c7e",
  button_fg = "#c8d3f5",
  button_bg = "#1b1d2b",
  button_hover_fg = "#ffffff",
  button_hover_bg = "#444a73",
}

return config
