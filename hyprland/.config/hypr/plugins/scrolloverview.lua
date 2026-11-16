-- .config/hypr/hyprland.lua

if hl.plugin.scrolloverview ~= nil then
    hl.config({
        plugin = {
            scrolloverview = {
                gesture_distance = 300,
                scale = 0.4,
                workspace_gap = 100,
                layout = "vertical",
                wallpaper = 2,
                blur = true,

                shadow = {
                    enabled = true,
                    range = 30,
                },
            },
        },
    })

    -- Abrir (fora do overview)
    hl.bind("ALT + TAB", function()
        hl.plugin.scrolloverview.overview("toggle all")
    end)

    -- Submap ativado automaticamente ao abrir o overview.
    -- Definir esse submap substitui a navegação padrão, então ela é recriada aqui.
    hl.define_submap("scrolloverview", function()
        hl.bind("left",  hl.plugin.scrolloverview.navigate("left"))
        hl.bind("right", hl.plugin.scrolloverview.navigate("right"))
        hl.bind("up",    hl.plugin.scrolloverview.navigate("up"))
        hl.bind("down",  hl.plugin.scrolloverview.navigate("down"))

        hl.bind("A", hl.plugin.scrolloverview.navigate("left"))
        hl.bind("D", hl.plugin.scrolloverview.navigate("right"))
        hl.bind("W", hl.plugin.scrolloverview.navigate("up"))
        hl.bind("S", hl.plugin.scrolloverview.navigate("down"))

        hl.bind("return", hl.plugin.scrolloverview.overview("off"))
        hl.bind("escape", hl.plugin.scrolloverview.overview("off"))

        -- Binds normais não valem dentro do submap, então o ALT+TAB precisa fechar aqui também
        hl.bind("ALT + TAB", hl.plugin.scrolloverview.overview("off"))

        -- Clique esquerdo: seleciona a janela/workspace e fecha (comportamento padrão)
        hl.bind("mouse:272", function()
            hl.plugin.scrolloverview.overview("select")
            hl.plugin.scrolloverview.window("select")
            hl.plugin.scrolloverview.overview("off")
        end, { mouse = true })

        -- Clique do meio: fecha a janela sob o cursor
        hl.bind("mouse:274", hl.plugin.scrolloverview.window("close"), { mouse = true })
        hl.bind("Q", hl.plugin.scrolloverview.window("close"))
    end)

    -- Waybar: esconde ao entrar no overview e mostra ao sair
    local bar_hidden = false

    hl.on("keybinds.submap", function()
        local in_overview = hl.get_current_submap() == "scrolloverview"
        if in_overview ~= bar_hidden then
            bar_hidden = in_overview
            hl.exec_cmd("pkill -SIGUSR1 waybar")
        end
    end)
end
