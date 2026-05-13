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

hl.window_rule({ match = { class = "^(org.gnome.Calendar|org.gnome.Weather|org.gnome.Calculator|org.gnome.clocks)$" }, size = "800 600", float = true, center = true})

hl.window_rule({ match = { class = "^(org.gnome.FileRoller)$", title = "^(Comprimir).*" }, float = true, center = true})

hl.window_rule({ match = { class = ".*(hunar)$" }, size = "1280 720", float = true, center = true})

hl.window_rule({ match = { class = ".*(hunar)$", title = "^(Renomear).*" }, size = "360 120", float = true, center = true})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

hl.layer_rule({ match = { namespace = ".*" }, blur = true, ignore_alpha = 0.69 })

hl.layer_rule({ match = { namespace = "selection|awww-daemon|logout_dialog|hyprpicker" }, animation = "fade"})

hl.layer_rule({ match = { namespace = "dock-popup"}, animation = "popin"})

hl.layer_rule({ match = { namespace = "rofi|swaync-control-center" }, dim_around = true})


