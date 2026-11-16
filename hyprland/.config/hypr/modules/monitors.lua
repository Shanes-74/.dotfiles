------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local MAIN = "eDP-1"
hl.monitor({
    output =    MAIN,
    mode =      "highrr",
    position =  "0x0",
    scale =     1,
    vrr =       1,
})

-- 1-5 no notebook
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = MAIN, persistent = true, default = (i == 1) })
end

hl.monitor({
    output =   "",
    mode =     "preferred",
    position = "auto-right",
    scale =    1,
    vrr =      0,
})

-- 6-10 no externo (a regra só vale quando ele estiver conectado)
for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "", default = (i == 6) })
end

if not _G.__hypr_monitor_notify_loaded then
    _G.__hypr_monitor_notify_loaded = true

    local function notify(text)
        local cmd = string.format(
            'swayosd-client --custom-icon="video-display-symbolic" --custom-message="%s"',
            text
        )
        hl.exec_cmd(cmd)
    end

    hl.on("monitor.added", function(mon)
        if mon == nil or mon.name == nil or mon.name == MAIN then return end
        notify("Monitor conectado: " .. mon.name)
    end)

    hl.on("monitor.removed", function(mon)
        if mon == nil or mon.name == nil or mon.name == MAIN then return end
        notify("Monitor desconectado: " .. mon.name)
    end)
end
