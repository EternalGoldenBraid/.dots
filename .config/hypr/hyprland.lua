-- Native Hyprland Lua configuration (Hyprland 0.55+).

local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local hypr_dir = config_home .. "/hypr"

-- Monitor profiles and theme colors are generated separately.
dofile(hypr_dir .. "/monitors.lua")
dofile(hypr_dir .. "/workspaces.lua")
dofile(hypr_dir .. "/colors.generated.lua")

-- Theme/toolkit environment.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- Autostart processes run once when the Hyprland session starts.
hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --systemd HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE")
    hl.exec_cmd("hyprshade auto")
    hl.exec_cmd(hypr_dir .. "/scripts/auto-monitor-profile.sh watch")
    hl.exec_cmd("foot")
end)

hl.config({
    input = {
        kb_layout = "us,fi",
        kb_options = "grp:alt_space_toggle",
        follow_mouse = 1,
        sensitivity = 0,
    },
    general = {
        border_size = 3,
        layout = "dwindle",
    },
    decoration = {
        fullscreen_opacity = 1.0,
        active_opacity = 1.0,
        inactive_opacity = 0.84,
        dim_inactive = true,
        dim_strength = 0.06,
        rounding = 6,
    },
    misc = {
        disable_hyprland_logo = true,
    },
})

-- Calendar popup.
hl.window_rule({
    name = "calendar-popup",
    match = { class = "^(calendar-popup)$" },
    float = true,
    center = true,
    size = { 920, 720 },
})

local main_mod = "SUPER"

-- System.
hl.bind(main_mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(main_mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + SHIFT + S", hl.dsp.exec_cmd("systemctl suspend"))

-- Applications.
hl.bind(main_mod .. " + O", hl.dsp.exec_cmd("/home/nicklas/.dotfiles/bin/handy-waybar-toggle"))
hl.bind(main_mod .. " + SHIFT + O", hl.dsp.exec_cmd("/home/nicklas/.dotfiles/bin/hypridle-bypass-toggle"))
hl.bind(main_mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(main_mod .. " + SHIFT + W", hl.dsp.exec_cmd("nautilus"))
hl.bind(main_mod .. " + D", hl.dsp.exec_cmd("~/.config/rofi/scripts/launch.sh -show drun"))
hl.bind(main_mod .. " + C", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
hl.bind(main_mod .. " + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-grep-open.sh"))
hl.bind(main_mod .. " + SHIFT + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/bin-scripts-launcher.sh"))
hl.bind(main_mod .. " + T", hl.dsp.exec_cmd("~/bin/rofi_tmux.sh"))

-- Screenshots.
hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("CTRL + ALT + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" ~/Media/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png]]))

-- Lock screen, audio, and brightness.
hl.bind(main_mod .. " + SHIFT + X", hl.dsp.exec_cmd("hyprlock"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --increase 5"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer --decrease 5"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer --toggle-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +10%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { repeating = true })

-- Focus and movement.
hl.bind(main_mod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(main_mod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(main_mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(main_mod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(main_mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(main_mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(main_mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(main_mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

-- Layout manipulation.
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(main_mod .. " + SHIFT + space", hl.dsp.window.float())
hl.bind(main_mod .. " + P", hl.dsp.workspace.move({ monitor = "+1" }))
hl.bind(main_mod .. " + E", hl.dsp.layout("togglesplit"))

-- Workspaces: SUPER+[0-9] switches, SUPER+SHIFT+[0-9] moves a window.
for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

-- Resize submap.
hl.bind(main_mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
    hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)
