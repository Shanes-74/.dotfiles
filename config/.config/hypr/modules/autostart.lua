-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function () 
   --hl.exec_cmd("hyprpm reload")
   hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")
   hl.exec_cmd("dbus-update-activation-environment --systemd --all")
   hl.exec_cmd("wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store")
   hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
   hl.exec_cmd("systemctl --user restart --now swaync swayosd")
   hl.exec_cmd("pgrep -x hypridle || hypridle")
   hl.exec_cmd("awww-daemon")
   hl.exec_cmd("waybar")
   hl.exec_cmd("hypr-dock-autohide")
end)
