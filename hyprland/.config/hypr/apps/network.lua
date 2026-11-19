-- network-watchdog.lua
-- Watchdog agressivo (5s) via PING, mas só quando há um jogo REALMENTE em execução.
-- Combina GameMode com verificação de PID vivo para evitar pings desnecessários.

local INTERFACE = "wlan0"
local PING_TARGET = "1.1.1.1"
local PING_COUNT = 1
local PING_TIMEOUT_S = 1
local CHECK_INTERVAL_MS = 5000
local MAX_FAILURES = 1
local RECOVERY_GRACE_CHECKS = 2

local failure_count = 0
local skip_checks = 0
local was_gaming = false

-- Camada 1: pergunta ao daemon se o GameMode está ativo.
local function gamemode_active()
    local handle = io.popen("gamemoded -s 2>/dev/null; echo 'EXIT:'$?")
    if not handle then return false end
    local output = handle:read("*a") or ""
    handle:close()

    -- Exit code 0 = inativo. Qualquer outro = ativo (por convenção do gamemoded).
    local exit_code = output:match("EXIT:(%d+)") or "1"
    if exit_code == "0" then return false end

    local lower = output:lower()
    return lower:find("active", 1, true) ~= nil
        and lower:find("inactive", 1, true) == nil
end

-- Camada 2: verifica se existe algum cliente registrado com PID ainda vivo.
--   true  → pelo menos um PID vivo (jogo rodando)
--   false → PIDs listados, mas todos mortos (jogo fechou)
--   nil   → impossível verificar (gamemoded -r indisponível)
local function gamemode_has_live_client()
    local handle = io.popen("gamemoded -r 2>/dev/null")
    if not handle then return nil end
    local output = handle:read("*a") or ""
    handle:close()

    local found_any_pid = false
    -- O formato típico é uma linha por cliente: "  - 12345: nome_do_jogo"
    for pid_str in output:gmatch("(%d+)") do
        local pid = tonumber(pid_str)
        if pid and pid > 1 then
            found_any_pid = true
            local f = io.open("/proc/" .. pid, "r")
            if f then
                f:close()
                return true
            end
        end
    end

    if found_any_pid then return false end
    return nil -- nenhum PID no output → não dá pra concluir nada
end

-- Combina as duas camadas.
local function is_really_gaming()
    if not gamemode_active() then return false end
    local live = gamemode_has_live_client()
    if live == nil then
        -- Fallback: se não conseguimos listar PIDs, confia no GameMode.
        return true
    end
    return live
end

-- Executa um ping curto e retorna se houve resposta.
local function ping_succeeds()
    local cmd = string.format(
        "ping -c %d -W %d -n -q %s >/dev/null 2>&1; echo 'EXIT:'$?",
        PING_COUNT, PING_TIMEOUT_S, PING_TARGET
    )
    local handle = io.popen(cmd)
    if not handle then return false end
    local output = handle:read("*a") or ""
    handle:close()
    return output:find("EXIT:0", 1, true) ~= nil
end

local function check_network()
    local gaming = is_really_gaming()

    -- Fora do jogo: não pinga, reseta estado, e loga a transição.
    if not gaming then
        if was_gaming then
            print("[Network Watchdog] Jogo encerrado. Watchdog em espera (sem ping).")
        end
        was_gaming = false
        failure_count = 0
        skip_checks = 0
        return
    end

    -- Transição: começou a jogar agora.
    if not was_gaming then
        print(string.format(
            "[Network Watchdog] Jogo detectado. Iniciando pings a %s a cada %ds.",
            PING_TARGET, CHECK_INTERVAL_MS / 1000
        ))
        was_gaming = true
        failure_count = 0
        skip_checks = 0
    end

    -- Janela de carência após uma recuperação.
    if skip_checks > 0 then
        skip_checks = skip_checks - 1
        return
    end

    if ping_succeeds() then
        failure_count = 0
    else
        failure_count = failure_count + 1
        print(string.format("[Network Watchdog] Ping falhou (%d/%d).", failure_count, MAX_FAILURES))
    end

    if failure_count >= MAX_FAILURES then
        print("[Network Watchdog] Falha de conectividade durante o jogo. Recuperando " .. INTERFACE .. "...")
        io.popen(string.format(
            "nmcli device disconnect %s && nmcli device connect %s &",
            INTERFACE, INTERFACE
        ))
        failure_count = 0
        skip_checks = RECOVERY_GRACE_CHECKS
    end
end

local watchdogTimer = hl.timer(check_network, { timeout = CHECK_INTERVAL_MS, type = "repeat" })
print("[Network Watchdog] Iniciado. Ping só durante gameplay real (GameMode + PID vivo).")
