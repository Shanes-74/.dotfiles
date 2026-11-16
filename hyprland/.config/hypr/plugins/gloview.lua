if hl.plugin.gloview ~= nil then
    local colors = require("modules.colors")
    local mainMod = "ALT"

    hl.bind(mainMod .. " + TAB", hl.plugin.gloview.toggle)
    --hl.bind(mainMod .. " + SHIFT + TAB", hl.plugin.gloview.desktop)
    --hl.bind(mainMod .. " + CTRL + TAB", hl.plugin.gloview.allworkspaces)

    --hl.bind(mainMod .. " + right", hl.plugin.gloview.next)
    --hl.bind(mainMod .. " + left", hl.plugin.gloview.prev)

    for w = 0, 9 do
        --hl.bind(mainMod .. " + " .. w, function() hl.plugin.gloview.setworkspace(w) end)
    end

    hl.config({
        plugin = {
            gloview = {
                layout         = "rows",
                gap            = 24,
                padding        = 80,
                padding_top    = 40,
                padding_bottom = 70,
                max_scale      = 1.0,
                duration       = 200,
                preview_round  = 20,
                blur           = 1,

                switch_animation = 1,
                switch_duration  = 300,
                move_animation   = 1,
                move_duration    = 250,

                anchor           = "top",
                strip_offset     = 0,
                strip_height     = 150,
                strip_margin     = 22,
                strip_gap        = 18,
                strip_card_round = 10,

                focus_follows_mouse       = 1,
                scroll_switches_workspace = 1,
                passthrough_keys          = 1,
                exit_on_click             = 1,
                exit_on_switch            = 1,

                key_close = "ESCAPE",
                key_next_workspace = "RIGHT",
                key_prev_workspace = "LEFT",
                key_activate  = "ENTER",
                key_close_window = "Q",
                key_left      = "A",
                key_right     = "D",
                key_up        = "W",
                key_down      = "S",
                key_desktop   = "",
                key_all_workspaces = "CTRL",
                key_workspace = "1,2,3,4,5,6,7,8,9,0",

                show_all_workspaces     = 0,
                show_empty              = 1,
                dynamic_workspaces      = 0,
                autodelete_empty        = 0,
                show_workspace_labels   = 1,
                show_window_labels      = 1,
                show_special            = 1,
                strip_all_card          = 1,
                drag_to_swap            = 1,
                switch_on_drop          = 1,
                switch_on_new_workspace = 1,

                hide_top_layers     = 1,
                hide_overlay_layers = 1,
                above_namespaces    = "",
                debug_logs = 0,

                select_border_size  = 2,
                select_border       = colors.outline, --0xf066ccff,

                close_button_color  = colors.error, --0xe6e23b3b,
                backdrop_color      = 0x40000000,

                strip_band_color    = colors.surface, --0x24ffffff,
                strip_card_color    = colors.surface_container_high, --0x3a0e131c,
                strip_active_color  = colors.outline, --0x4d1c2c44,
                strip_active_border = colors.primary, --0xf0ffffff,
                strip_hover_border  = colors.outline_variant, --0x80ffffff,
                strip_active_border_size = 2,
                strip_hover_border_size  = 2,
                strip_plus_color    = colors.primary, --0xd0eef4ff,

                preview_bg          = colors.outline_variant, --0xff14181f,
                shadow_color        = colors.shadow, --0x70000000,

                hover_border        = colors.primary, --0xf0ffffff,
                hover_border_size   = 2,
            },
        },
    })
end
