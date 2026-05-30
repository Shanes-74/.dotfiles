#!/usr/bin/env bash

# =====================================================
# HYPRIDLE INHIBIT TOGGLE — Notificação única e limpa
# =====================================================

LOCKFILE="/tmp/hypridle-inhibit.lock"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hypridle-toggle"
NOTIF_ID_FILE="$CACHE_DIR/notif_id"

mkdir -p "$CACHE_DIR"

# Função de notificação padronizada (igual aos outros scripts)
notify() {
    local msg="$1"
    local urgency="${2:-low}"
    local timeout=2000

    local replace_id=0
    [[ -f "$NOTIF_ID_FILE" ]] && replace_id=$(cat "$NOTIF_ID_FILE")

    local new_id
    new_id=$(notify-send \
        --urgency="$urgency" \
        -r "$replace_id" \
        -t "$timeout" \
        -p \
        --hint=int:transient:1 \
        "Hypridle" "$msg" 2>/dev/null)

    [[ -n "$new_id" ]] && echo "$new_id" > "$NOTIF_ID_FILE"
}

get_state() {
    if [ -f "$LOCKFILE" ]; then
        echo "paused"
    else
        echo "running"
    fi
}

case "$1" in
    toggle)
        if [ -f "$LOCKFILE" ]; then
            # reativa o idle
            kill "$(cat "$LOCKFILE")" 2>/dev/null
            rm -f "$LOCKFILE"
            notify "Idle Automático Ativado" "low"
        else
            # pausa o idle (modo avançado)
            systemd-inhibit --what=idle --why="Hypridle toggle" sleep infinity &
            echo $! > "$LOCKFILE"
            notify "Idle Automático Pausado" "low"
        fi
        ;;
    *)
        state=$(get_state)

        if [ "$state" = "paused" ]; then
            echo '{"text":"󰒳","class":"active","tooltip":"Idle pausado"}'
        else
            echo '{"text":"󰒲","class":"inactive","tooltip":"Idle ativo"}'
        fi
        ;;
esac