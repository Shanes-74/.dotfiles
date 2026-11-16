-- hyprbars.lua

if hl.plugin.hyprbars ~= nil then
    local colors = require("modules.colors")

    hl.config({
        plugin = {
            hyprbars = {
                enabled = true,
                bar_blur = true,
                bar_title_enabled = true,
                bar_part_of_window = true,
                bar_precedence_over_border = true,
                icon_on_hover = true,

                bar_color = colors.background,
                ["col.text"] = colors.on_surface,

                bar_text_font = "Google Sans Display",
                bar_text_weight = "medium",
                bar_text_align = "center",
                bar_buttons_alignment = "left",

                bar_height = 40,
                bar_text_size = 15,
                bar_button_padding = 8,
                bar_padding = 15,

                inactive_button_color = colors.outline_variant,
                on_double_click = "hyprctl dispatch 'hl.dsp.window.float({action=\"toggle\"})'",
            },
        },
    })

    -- botões (ordem: direita -> esquerda)

    local close = "hyprctl dispatch 'hl.dsp.window.close()'"
    local minimize = "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:minimized\", follow = false })'"
    local float = "hyprctl dispatch 'hl.dsp.window.float({action=\"toggle\"})'"

    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(d95353)", -- Vermelho fosco / equilibrado
        fg_color = colors.surface,
        size = 20,
        icon = "",
        action = close,
    })

    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(dcd033)", -- Amarelo quente / fosco
        fg_color = colors.surface,
        size = 20,
        icon = "",
        action = minimize,
    })

    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(53c953)", -- Verde equilibrado
        fg_color = colors.surface,
        size = 20,
        icon = "󰘖",
        action = float,
    })

    local hyprbarsEnabled = true
    local BAR_HEIGHT = 40 -- a mesma altura que você já usa lá em cima

    hl.bind("SUPER + CTRL + B", function()
        hyprbarsEnabled = not hyprbarsEnabled
        hl.config({
            plugin = {
                hyprbars = {
                    enabled = hyprbarsEnabled,
                    bar_height = hyprbarsEnabled and BAR_HEIGHT or 0,
                },
            },
        })
    end)

    --hl.bind("SUPER + M", hl.dsp.workspace.toggle_special("minimized"))
    --hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd(minimize))
end
