-- keys.lua for WezTerm - Vim-style keybindings inspired by your Neovim setup
local wezterm = require 'wezterm'

local keys = {
  -- Pane navigation like Vim splits
  {key="h", mods="CTRL", action=wezterm.action.ActivatePaneDirection("Left")},
  {key="j", mods="CTRL", action=wezterm.action.ActivatePaneDirection("Down")},
  {key="k", mods="CTRL", action=wezterm.action.ActivatePaneDirection("Up")},
  {key="l", mods="CTRL", action=wezterm.action.ActivatePaneDirection("Right")},

  -- Resize panes with Alt+H/J/K/L
  {key="h", mods="ALT", action=wezterm.action.AdjustPaneSize{"Left", 3}},
  {key="j", mods="ALT", action=wezterm.action.AdjustPaneSize{"Down", 3}},
  {key="k", mods="ALT", action=wezterm.action.AdjustPaneSize{"Up", 3}},
  {key="l", mods="ALT", action=wezterm.action.AdjustPaneSize{"Right", 3}},

  -- Tab management similar to Vim tabs
  {key="t", mods="CTRL", action=wezterm.action.SpawnTab("CurrentPaneDomain")},
  {key="w", mods="CTRL", action=wezterm.action.CloseCurrentTab{confirm=true}},
  {key="n", mods="CTRL", action=wezterm.action.ActivateTabRelative(1)},
  {key="p", mods="CTRL", action=wezterm.action.ActivateTabRelative(-1)},

  -- Splits: horizontal and vertical (like :split / :vsplit)
  {key="s", mods="CTRL", action=wezterm.action.SplitHorizontal{domain="CurrentPaneDomain"}},
  {key="v", mods="CTRL", action=wezterm.action.SplitVertical{domain="CurrentPaneDomain"}},

  -- Copy/paste like system clipboard
  {key="y", mods="CTRL", action=wezterm.action.CopyTo("Clipboard")},
  {key="p", mods="CTRL", action=wezterm.action.PasteFrom("Clipboard")},

  -- Search like `/` in Vim
  {key="f", mods="CTRL", action=wezterm.action.Search{CaseInSensitiveString=""}},

  -- Clear scrollback
  {key="l", mods="CTRL|SHIFT", action=wezterm.action.ClearScrollback("ScrollbackAndViewport")},

  -- Toggle full screen
  {key="Enter", mods="ALT", action=wezterm.action.ToggleFullScreen},

  -- Open config quickly (like <leader>ev)
  {key="e", mods="LEADER", action=wezterm.action.SpawnCommandInNewTab{
    args={"nvim", os.getenv("WEZTERM_CONFIG_FILE") or "~/.config/wezterm/wezterm.lua"}}},
}

return { keys = keys }
