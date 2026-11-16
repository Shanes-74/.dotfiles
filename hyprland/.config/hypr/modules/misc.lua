----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        animate_mouse_windowdragging = true,
        animate_manual_resizes       = true,

        on_focus_under_fullscreen = 1, -- 0 = do nothing, 1 = focus, 2 = focus and raise

        disable_hyprland_logo    = true, -- If true disables the random hyprland logo / anime girl background. :(
        disable_splash_rendering = true,
        focus_on_activate        = true,

        --vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,

        font_family = "Google Sans Display Regular",

        enable_swallow = false,
        swallow_regex  = "^(kitty|firefox)$",
    },

    ecosystem = {
        no_donation_nag = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})
