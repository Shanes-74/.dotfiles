-- ~/.config/hypr/brightness.lua
local DISPLAY = 1
local STEP = 5
local DEBOUNCE = 150 -- ms

local function read_level()
    local p = io.popen("ddcutil getvcp 10 --display " .. DISPLAY .. " 2>/dev/null")
    local out = p:read("*a")
    p:close()
    return tonumber(out:match("current value =%s*(%d+)"))
end

-- sem monitor DDC: o módulo não carrega (nenhum bind é registrado)
local level = read_level()
if not level then return end

local pending = nil

local function osd(value)
    hl.exec_cmd(string.format(
        [[swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("HDMI")) | .name' | head -n1)" --custom-progress %.2f --custom-progress-text '%d%%' --custom-icon display-brightness-symbolic]],
        value / 100, value))
end

local function apply()
    hl.exec_cmd(string.format("ddcutil setvcp 10 %d --display %d --noverify", level, DISPLAY))
    pending = nil
end

local function change(delta)
    level = math.max(0, math.min(100, level + delta))
    osd(level)

    if pending then pending:set_enabled(false) end
    pending = hl.timer(apply, { timeout = DEBOUNCE, type = "oneshot" })
end

hl.bind("ALT + bracketright", function() change(STEP) end, { locked = true, repeating = true })
hl.bind("ALT + bracketleft",  function() change(-STEP) end, { locked = true, repeating = true })
