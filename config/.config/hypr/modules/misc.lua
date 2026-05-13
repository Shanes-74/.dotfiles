----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        animate_mouse_windowdragging = true,
        animate_manual_resizes = true,
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
        disable_splash_rendering = true,
        focus_on_activate = true,

        vrr = 1,

        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,

        font_family = "GeistMono Nerd Font Mono",

        enable_swallow = false,
        swallow_regex = "^(kitty|firefox)$",
    },

    ecosystem = {
        no_donation_nag = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})