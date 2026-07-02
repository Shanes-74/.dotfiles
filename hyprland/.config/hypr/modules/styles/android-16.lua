-----------------------
---- LOOK AND FEEL ----
-----------------------

local colors = require("modules.colors")

hl.config({

    general = {
        gaps_in  = 5,
        gaps_out = 15,
        border_size = 1,

        col = {
            active_border   = colors.outline_variant,
            inactive_border = colors.surface_container_low,
        },

        resize_on_border = true,
        allow_tearing = false,
    },

    decoration = {
        rounding       = 20,
        rounding_power = 2,
        active_opacity   = 1,
        inactive_opacity = 1,
        dim_around   = 0.35,
        dim_inactive = 1,
        dim_special  = 0.25,
        dim_strength = 0.25,
        
        shadow = {
            enabled      = false,
            range        = 16,
            render_power = 3,
            color        = 0xee121212,
        },

        blur = {
            enabled = true,
            new_optimizations = true,
            xray = false,
            ignore_opacity = true,
            popups = true,
            special = true,
            size = 20,
            passes = 3,
            vibrancy = 0.2,
            vibrancy_darkness = 0.2,
            noise = 0.05,
            contrast = 1.5,
            brightness = 1,
        },

    },

    animations = { enabled = true },

})

-- ==============================================
-- ANDROID-LIKE ANIMATIONS
-- ==============================================

--require("modules.animations.android")
require("modules.animations.macos")

---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({ match = { namespace = ".*" }, blur = true, ignore_alpha = 0.69 })

hl.layer_rule({ match = { namespace = "selection|awww-daemon|logout_dialog|hyprpicker" }, animation = "fade"})

hl.layer_rule({ match = { namespace = "dock-popup"}, animation = "popin"})

hl.layer_rule({ match = { namespace = "swaync-control-center|swaync-notification-window"}, animation = "slide top"})

hl.layer_rule({ match = { namespace = "waybar" }, animation = "slide top"})
