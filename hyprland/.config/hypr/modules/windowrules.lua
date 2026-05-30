--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({ match = { class = ".*" }, workspace = "unset"})

hl.window_rule({ match = { float = true }, center = true})

hl.window_rule({ match = { class = "hyprland-share-picker" }, size = "420 480", float = true})

hl.window_rule({ match = { title = "^Steam$" }, size = "1280 720", center = true})
hl.window_rule({ match = { class = "steam" },   float = true})

hl.window_rule({ match = { class = "^(python).*", title = "^(ACCELA|Settings).*" }, size = "720 720", float = true, center = true})

hl.window_rule({ match = { class = "DivAcerManagerMax" }, size = "1280 720", float = true, center = true})

hl.window_rule({ match = { class = "^(org.gnome.Calculator|blueman-manager|com.network.manager)$" }, size = "550 600", float = true, center = true})

hl.window_rule({ match = { class = "org.pulseaudio.pavucontrol" }, size = "760 600", float = true, center = true})

hl.window_rule({ match = { class = "^(Spotify|spotify)$" }, size = "1280 720", float = true, center = true})

hl.window_rule({ match = { class = "^(org.gnome.Calendar|org.gnome.Weather|org.gnome.clocks)$" }, size = "800 600", float = true, center = true})

hl.window_rule({ match = { class = "org.gnome.Calculator" }, size = "480 640", float = true, center = true})

hl.window_rule({ match = { class = "^(org.gnome.FileRoller)$", title = "^(Comprimir).*" }, float = true, center = true})

hl.window_rule({ match = { class = ".*(hunar)$", title = ".*(- Thunar)$" },                    size = "1280 720", float = true, center = true})
hl.window_rule({ match = { class = ".*(hunar)$", title = "^(Renomear).*" },                    size = "480 120", float = true, center = true})
hl.window_rule({ match = { class = ".*(hunar)$", title = "Andamento da operação de arquivo" }, size = "480 120", float = true, center = true})