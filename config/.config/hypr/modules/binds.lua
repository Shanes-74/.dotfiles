---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local bar =          "killall waybar || waybar &"
local dock =         "killall hypr-dock-autohide || hypr-dock-autohide &"
local browser =      "librewolf"
local terminal =     "kitty"
local launcher =     "rofi -show drun || pkill rofi"
local powermenu =    "~/.config/scripts/power-menu/powermenu.sh"
local lockscreen =   "hyprlock"
local filemanager =  "thunar"
local editor =       "code"
local clipboard =    "~/.config/scripts/clipboard/clipboard.sh"
local notifycenter = "swaync-client -R -rs -t"
local playermusic =  "spotify"


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

local shortcuts = {
    mainMod .. " + CTRL + L",
    "XF86PowerOff",
}

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- Exec Defaults
for _, key in ipairs(shortcuts) do
    hl.bind(key, hl.dsp.exec_cmd(powermenu))
end

hl.bind(mainMod .. " + SPACE",          hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + L",              hl.dsp.exec_cmd(lockscreen))
hl.bind(mainMod .. " + E",              hl.dsp.exec_cmd(filemanager))
hl.bind(mainMod .. " + SUPER_L",        hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + B",              hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + ESCAPE",         hl.dsp.exec_cmd(bar))
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd(dock))
hl.bind(mainMod .. " + C",              hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + V",              hl.dsp.exec_cmd(clipboard))
hl.bind(mainMod .. " + P",              hl.dsp.exec_cmd(notifycenter))
hl.bind(mainMod .. " + SHIFT + M",      hl.dsp.exec_cmd(playermusic))

-- Exec
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/scripts/wallpaper/wallmenu.py"))
hl.bind("SHIFT + CTRL + L",        hl.dsp.exec_cmd("swaync-client -C"))
hl.bind(mainMod .. " + Z",         hl.dsp.exec_cmd("flatpak run com.rtosta.zapzap"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("night-mode"))
hl.bind(mainMod .. " + H",         hl.dsp.exec_cmd("~/.config/waybar/custom-modules/hypridle/hypridle.sh toggle"))
hl.bind("XF86Launch1",             hl.dsp.exec_cmd("DAMX"))

-- Window
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("F11",             hl.dsp.window.fullscreen(3))
hl.bind("ALT + F",         hl.dsp.window.pin())

hl.bind(mainMod .. " + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())   -- Change focus to another window
    hl.dispatch(hl.dsp.window.bring_to_top()) -- Bring it to the top
end)

--hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- Capture Screen
hl.bind("PRINT",               hl.dsp.exec_cmd("printshot full"))
hl.bind("SHIFT + PRINT",       hl.dsp.exec_cmd("printshot region"))
hl.bind("ALT + PRINT",         hl.dsp.exec_cmd("printshot monitor"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("printshot window"))

-- Move focus with mainMod + AWSD
hl.bind(mainMod .. " + A", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + D", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + W", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + S", hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + arrow keys
hl.bind(mainMod .. " + LEFT",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + UP",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + DOWN",  hl.dsp.window.move({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
--hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
--hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume +5"),          { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume -5"),          { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness +5"),             { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -5"),             { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("swayosd-client --playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("swayosd-client --playerctl previouss"),  { locked = true })