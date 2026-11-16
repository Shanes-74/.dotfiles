local weTurnedOnDnd = false

local function focusedWsHasFS2()
    local mon = hl.get_active_monitor()
    if not mon then return false end
    local ws = mon.active_workspace
    if not ws then return false end
    for _, w in ipairs(ws:get_windows()) do
        if w.fullscreen == 2 then
            return true
        end
    end
    return false
end

local function refreshDND()
    local shouldBeActive = focusedWsHasFS2()

    if shouldBeActive then
        local handle = io.popen("swaync-client -D")
        if not handle then
            return
        end

        local out = handle:read("*a")
        handle:close()

        if not out or out:match("true") == nil then
            hl.exec_cmd("swaync-client -dn")
            weTurnedOnDnd = true
        end
    else
        if weTurnedOnDnd then
            hl.exec_cmd("swaync-client -df")
            weTurnedOnDnd = false
        end
    end
end

hl.on("window.fullscreen", refreshDND)
hl.on("workspace.active", refreshDND)
