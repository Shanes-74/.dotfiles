-- =========================================
-- AUTOCLICK: CONFIGURAÇÃO
-- =========================================

-- 1) Mouse com intervalo (via dotool)
local AUTOCLICK_MOUSE = {
    bind     = "ALT + C",
    interval = 100,                 -- ms entre cliques
    button   = "left",              -- left | right | middle
}

-- 2) Teclas com intervalo (send_key_state: down + up a cada envio)
local AUTOCLICK_KEY = {
    bind     = "SUPER + F8",
    interval = 100,                 -- ms entre envios
    keys     = { "Z", "B", "E", "G" },   -- aceita "mouse:272"
    together = false,               -- false = uma por vez; true = todas juntas (down em todas, depois up)
    mods     = "",                  -- ex: "CTRL", "SHIFT"
    window   = nil,                 -- ex: "class:^(firefox)$"; nil = janela focada
}

-- 3) Segurar, sem intervalo (send_key_state down: pressiona e não solta)
local AUTOCLICK_HOLD = {
    bind     = "SUPER + F9",
    keys     = { "mouse:272", "S" },     -- pode ter várias, todas ficam pressionadas
    mods     = "",
    window   = nil,
}

-- =========================================
-- AUTOCLICK: LÓGICA
-- =========================================

local function autoclick(keys, interval, action)
    local on, gen = false, 0

    local function tick(g)
        if not on or g ~= gen then return end
        action()
        hl.timer(function() tick(g) end, { timeout = interval, type = "oneshot" })
    end

    hl.bind(keys, function()
        on = not on
        if on then gen = gen + 1; tick(gen) end
    end)
end

local function key_state(cfg, key, state)
    hl.dispatch(hl.dsp.send_key_state({
        mods   = cfg.mods,
        key    = key,
        window = cfg.window,
        state  = state,
    }))
end

autoclick(AUTOCLICK_MOUSE.bind, AUTOCLICK_MOUSE.interval, function()
    hl.dispatch(hl.dsp.exec_cmd("echo click " .. AUTOCLICK_MOUSE.button .. " | dotool"))
end)

autoclick(AUTOCLICK_KEY.bind, AUTOCLICK_KEY.interval, function()
    local cfg = AUTOCLICK_KEY
    if cfg.together then
        for _, k in ipairs(cfg.keys) do key_state(cfg, k, "down") end
        for _, k in ipairs(cfg.keys) do key_state(cfg, k, "up") end
    else
        for _, k in ipairs(cfg.keys) do
            key_state(cfg, k, "down")
            key_state(cfg, k, "up")
        end
    end
end)

hl.bind(AUTOCLICK_HOLD.bind, function()
    for _, k in ipairs(AUTOCLICK_HOLD.keys) do key_state(AUTOCLICK_HOLD, k, "down") end
end)
