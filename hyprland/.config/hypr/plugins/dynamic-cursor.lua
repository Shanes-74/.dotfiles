if hl.plugin.dynamic_cursors ~= nil then
    hl.config { plugin = { dynamic_cursors = {
        enabled = true,
        mode = "stretch",
        threshold = 1,

        stretch = {
            limit = 3000,
            activation = "quadratic",
            window = 100,
        },

        shake = {
            enabled = true,
            threshold = 6.0,
            base = 2.5,
            speed = 4.0,
            influence = 1,
            limit = 0,
            timeout = 2000,
            effects = false,
            ipc = false,
        },

        hyprcursor = {
            enabled = true,
            nearest = 0,
            resolution = -1,
            fallback = "clientside",
        },
    }}}

    -- Desativa o shake (cursor grande) quando a janela ativa está em fullscreen
    local function update_shake()
        local w = hl.get_active_window()
        local fs = w ~= nil and (w.fullscreen == 2 or w.fullscreen == 3)
        hl.config { plugin = { dynamic_cursors = { shake = { enabled = not fs } } } }
    end

    hl.on("window.fullscreen", update_shake)
    hl.on("window.active", update_shake)
    hl.on("config.reloaded", update_shake)
end
