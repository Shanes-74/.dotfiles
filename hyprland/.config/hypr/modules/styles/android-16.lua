-----------------------
---- LOOK AND FEEL ----
-----------------------

local colors = require("modules.colors")

hl.config({

    general = {
        gaps_in     = 5,
        gaps_out    = 15,
        border_size = 1,

        col = {
            active_border   = colors.outline_variant,
            inactive_border = colors.surface_container_low,
        },

        resize_on_border = true,
        allow_tearing    = false,
    },

    decoration = {
        rounding       = 20,
        rounding_power = 2,

        --active_opacity   = 0.70,
        --inactive_opacity = 0.85,

        dim_inactive = true,
        dim_around   = 0.25,
        dim_special  = 0.25,
        dim_strength = 0.25,

        shadow = {
            enabled      = false,
            range        = 15,
            render_power = 4,
            color        = 0x80000000,
        },

        blur = {
            variant = "haze",
            haze = {
                intensity   = 1.0,
                iridescence = 1.0,
            },

            enabled        = true,
            xray           = false,
            ignore_opacity = true,
            popups         = true,
            special        = true,
            input_methods  = true,

            input_methods_ignorealpha = 0.49,
            size                      = 5,
            passes                    = 2,
            noise                     = 0.03,
            contrast                  = 1.2,
            brightness                = 1,
        },

        motion_blur = {
            enabled = true,
            samples = 5,
        },

        wobble = { enabled = true },
    },

    animations = { enabled = true },

})

--------------------
---- ANIMATIONS ----
--------------------

require("modules.animations.android")
--require("modules.animations.macos")


---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({
    match = {
        namespace = ".*"
    },
    blur = true,
    ignore_alpha = 0.49,
    blur_popups = true,
})

hl.layer_rule({
    match = {
        namespace = "selection|awww-daemon|logout_dialog|hyprpicker"
    },
    animation = "fade"
})

hl.layer_rule({
    match = {
        namespace = "dock-popup"
    },
    animation = "popin"
})

hl.layer_rule({
    match = {
        namespace = "swaync-control-center|swaync-notification-window"
    },
    animation = "slide top"
})

hl.layer_rule({
    match = {
        namespace = "waybar"
    },
    animation = "slide top"
})

hl.layer_rule({
    match = {
        namespace = "cursor-clip"
    },
    animation = "slide bottom",
})


----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
    match = {
        class = ".*"
    },
    no_blur = true,
})

hl.window_rule({
    match = {
        class = "kitty"
    },
    size = "1080 640",
    float = true,
    center = true,
    no_blur = false,
})

hl.window_rule({
    match = {
        class = "zen"
    },
    no_blur = false,
    opacity = "0.85 0.85 1.0"
})
