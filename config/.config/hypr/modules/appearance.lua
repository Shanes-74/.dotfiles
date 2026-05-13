-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 12,

        border_size = 0,

        --col = {
            --active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            --inactive_border = "rgba(595959aa)",
        --},

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,
    },

    decoration = {
        rounding       = 25,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.85,
        inactive_opacity = 0.70,

        dim_around   = 0.35,
        dim_inactive = 1,
        dim_special  = 0.25,
        dim_strength = 0.25,
        dim_around   = 0.35,

        shadow = {
            enabled      = true,
            range        = 16,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled = true,
            new_optimizations = true,
            xray = false,
            ignore_opacity = true,
            popups = true,
            special = true,

            size = 3,
            passes = 4,
            vibrancy = 0.2,
            vibrancy_darkness = 0.2,
            noise = 0.05,
            contrast = 1.5,
            brightness = 1,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("android",     { type = "bezier", points = { {0.4, 0.0}, {0.2, 1.0} } })
hl.curve("androidIn",   { type = "bezier", points = { {0.3, 0.0}, {0.1, 1.0} } })
hl.curve("androidOut",  { type = "bezier", points = { {0.1, 0.0}, {0.3, 1.0} } })
hl.curve("androidSoft", { type = "bezier", points = { {0.35, 0.0}, {0.15, 1.0} } })
hl.curve("springIn",    { type = "bezier", points = { {0.18, 0.89}, {0.32, 1.10} } })
hl.curve("springOut",   { type = "bezier", points = { {0.6, -0.10}, {0.73, 0.05} } })
hl.curve("default",     { type = "bezier", points = { {0.4, 0.0}, {0.2, 1.0} } }) -- curva padrão do Hyprland

hl.animation({ leaf = "global",        enabled = true, speed = 5, bezier = "android" })
hl.animation({ leaf = "border",        enabled = true, speed = 4, bezier = "default" })

hl.animation({ leaf = "windows",       enabled = true, speed = 5, bezier = "android",      style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4, bezier = "springIn",     style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 5, bezier = "springOut",    style = "slide" })

hl.animation({ leaf = "fade",          enabled = true, speed = 4, bezier = "android" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 3, bezier = "springIn" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 4, bezier = "springOut" })

hl.animation({ leaf = "layers",        enabled = true, speed = 4, bezier = "android",      style = "slide" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4, bezier = "springIn",     style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 4, bezier = "springOut",    style = "slide" })

hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 3, bezier = "springIn" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 4, bezier = "springOut" })

hl.animation({ leaf = "workspaces",    enabled = true, speed = 5, bezier = "androidSoft",  style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 4, bezier = "springIn",     style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "springOut",    style = "slide" })

hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 4, bezier = "springIn" })