#!/usr/bin/env bash

LOCKFILE="/tmp/hypridle-inhibit.lock"

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
            notify-send "Hypridle" "Idle automático reativado"
        else
            # pausa o idle (modo avançado)
            systemd-inhibit --what=idle --why="Waybar idle toggle" sleep infinity &
            echo $! > "$LOCKFILE"
            notify-send "Hypridle" "Idle automático pausado"
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