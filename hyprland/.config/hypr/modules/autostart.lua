-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Linhas desativadas
--hl.exec_cmd("wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store")
--hl.exec_cmd("nwg-dock")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")
    --hl.exec_cmd("hyprlock")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("cursor-clip --daemon")
    hl.exec_cmd("hyprpm reload")
end)
