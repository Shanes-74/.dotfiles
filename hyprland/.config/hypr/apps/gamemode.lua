-- Game Mode
local css_file = "/tmp/gamemode.css"

local game_css = [[
window#waybar {
    background: @surface;
    border-bottom: 1px solid @outline_variant;
}

#left, #center, #right {
    margin: 0px;
    padding: 6px 5px 8px 5px;
    border-radius: 0px;
    background: transparent;
    border: none;
}
]]

-- Escreve o CSS (ou esvazia, com "") e manda a Waybar recarregar o estilo
local function write_css(content)
    local f = io.open(css_file, "w")
    f:write(content)
    f:close()
end

-- Qualquer hyprctl reload (atalho ou terminal) esvazia o CSS
hl.on("config.reloaded", function()
    write_css("")
end)

hl.bind("ALT + G", function()
    local game_mode = (hl.get_config("animations.enabled") == true)
    local pid_file = "/tmp/hypr_gamemode.pid"

    -- Função auxiliar para enviar notificação e salvar PID
    local function send_notification(summary, body, urgency)
        -- Lê o PID antigo
        local old_pid = ""
        local file = io.open(pid_file, "r")
        if file then
            old_pid = file:read("*all"):gsub("%s+", "")
            file:close()
        end

        -- Monta o comando com ou sem -r
        local cmd = "notify-send"
        if old_pid ~= "" then
            cmd = cmd .. " -r " .. old_pid
        end
        cmd = cmd .. " -p '" .. summary .. "' '" .. body .. "' -u " .. urgency .. " --hint=int:transient:1"

        -- Executa e captura o novo PID
        local new_pid = io.popen(cmd):read("*all"):gsub("%s+", "")

        -- Salva o novo PID
        local save_file = io.open(pid_file, "w")
        if save_file then
            save_file:write(new_pid)
            save_file:close()
        end
    end

    if game_mode then
        -- ATIVA modo jogo
        hl.config({
            general = {
                gaps_in     = 0,
                gaps_out    = 0,
                border_size = 0
            },

            animations = { enabled = false },

            decoration = {
                active_opacity   = 1,
                inactive_opacity = 1,
                rounding         = 0,

                shadow      = { enabled = false },
                blur        = { enabled = false },
                motion_blur = { enabled = false },
                wobble      = { enabled = false },
            },

            hl.layer_rule({
                match = {
                    namespace = ".*"
                },
                blur = false,
                blur_popups = false,
            })
        })

        --hl.plugin.hyprglass.config({ enabled = false, layers = { enabled = false } })

        write_css(game_css)
        send_notification("Modo de jogo ativado", "O modo de jogo foi ativado.", "critical")
        return
    end

    -- DESATIVA modo jogo (o reload dispara config.reloaded, que esvazia o CSS)
    hl.exec_cmd("hyprctl reload")
    send_notification("Modo de jogo desativado", "O modo de jogo foi desativado.", "critical")
end)
