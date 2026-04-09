#!/bin/bash

CONFIG="$HOME/.config/scripts/hypr-dock/autohide.json"

if [ ! -f "$CONFIG" ]; then
    echo "Arquivo de configuração não encontrado: $CONFIG"
    exit 1
fi

read_config() {
    python3 -c "
import json, sys
with open('$CONFIG') as f:
    c = json.load(f)
print(c.get('edge', 'bottom'))
print(c.get('activate_zone', 5))
print(c.get('safe_zone', 100))
print(c.get('safe_zone_popup', 300))
print(c.get('check_interval', 50))
print(c.get('hide_delay', 10))
print(c.get('activation_width', 400))
"
}

load_config() {
    local values
    values=$(read_config)
    EDGE=$(echo "$values" | sed -n '1p')
    ACTIVATE_ZONE=$(echo "$values" | sed -n '2p')
    SAFE_ZONE=$(echo "$values" | sed -n '3p')
    SAFE_ZONE_POPUP=$(echo "$values" | sed -n '4p')
    CHECK_INTERVAL=$(echo "$values" | sed -n '5p')
    HIDE_DELAY=$(echo "$values" | sed -n '6p')
    ACTIVATION_WIDTH=$(echo "$values" | sed -n '7p')
    SLEEP_TIME=$(python3 -c "print($CHECK_INTERVAL / 1000)")
}

cleanup() {
    pkill -x hypr-dock > /dev/null 2>&1
    rm -f /tmp/hypr-dock-autohide.pid
    exit 0
}

reload() {
    echo "→ Recarregando configuração..."
    pkill -x hypr-dock > /dev/null 2>&1
    exec "$0" "$@"
}

trap 'cleanup' SIGTERM SIGINT
trap 'reload' SIGUSR1

load_config
echo $$ > /tmp/hypr-dock-autohide.pid

LAST_MODIFIED=$(stat -c %Y "$CONFIG")

DOCK_VISIBLE=false
HIDE_TIMER=0

get_screen_height() {
    hyprctl monitors -j | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
for m in monitors:
    if m.get('focused'):
        print(m['height'])
        break
"
}

get_screen_width() {
    hyprctl monitors -j | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
for m in monitors:
    if m.get('focused'):
        print(m['width'])
        break
"
}

popup_is_open() {
    hyprctl layers 2>/dev/null | grep -q "namespace: dock-popup"
}

dock_is_running() {
    pgrep -x hypr-dock > /dev/null 2>&1
}

fullscreen_is_active() {
    hyprctl activewindow -j 2>/dev/null | python3 -c "
import json, sys
try:
    w = json.load(sys.stdin)
    print('yes' if w.get('fullscreen') else 'no')
except:
    print('no')
"
}

SCREEN_H=$(get_screen_height)
SCREEN_W=$(get_screen_width)

ACTIVATION_LEFT=$(( (SCREEN_W - ACTIVATION_WIDTH) / 2 ))
ACTIVATION_RIGHT=$(( ACTIVATION_LEFT + ACTIVATION_WIDTH ))

while true; do
    # Detecta mudança no JSON e recarrega
    CURRENT_MODIFIED=$(stat -c %Y "$CONFIG")
    if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ]; then
        reload
    fi

    POS=$(hyprctl cursorpos 2>/dev/null)
    MOUSE_X=$(echo "$POS" | awk '{print int($1)}' | tr -d ',')
    MOUSE_Y=$(echo "$POS" | awk '{print int($2)}')

    if [ "$DOCK_VISIBLE" = "true" ] && ! dock_is_running; then
        DOCK_VISIBLE=false
        HIDE_TIMER=0
    fi

    if [ "$DOCK_VISIBLE" = "false" ]; then
        CURRENT_ZONE=$ACTIVATE_ZONE
    elif popup_is_open; then
        CURRENT_ZONE=$SAFE_ZONE_POPUP
    else
        CURRENT_ZONE=$SAFE_ZONE
    fi

    case "$EDGE" in
        bottom) IN_ZONE=$(( MOUSE_Y >= SCREEN_H - CURRENT_ZONE )) ;;
        top)    IN_ZONE=$(( MOUSE_Y <= CURRENT_ZONE )) ;;
        left)   IN_ZONE=$(( MOUSE_X <= CURRENT_ZONE )) ;;
        right)  IN_ZONE=$(( MOUSE_X >= SCREEN_W - CURRENT_ZONE )) ;;
    esac

    case "$EDGE" in
        bottom|top) IN_CENTER=$(( MOUSE_X >= ACTIVATION_LEFT && MOUSE_X <= ACTIVATION_RIGHT )) ;;
        left|right) IN_CENTER=$(( MOUSE_Y >= ACTIVATION_LEFT && MOUSE_Y <= ACTIVATION_RIGHT )) ;;
    esac

    if [ "$IN_ZONE" = "1" ] && [ "$IN_CENTER" = "1" ]; then
        HIDE_TIMER=0
        if [ "$DOCK_VISIBLE" = "false" ] && [ "$(fullscreen_is_active)" != "yes" ]; then
            hypr-dock > /dev/null 2>&1 &
            DOCK_VISIBLE=true
        fi
    else
        if [ "$DOCK_VISIBLE" = "true" ]; then
            HIDE_TIMER=$(( HIDE_TIMER + 1 ))
            if [ "$HIDE_TIMER" -ge "$HIDE_DELAY" ]; then
                pkill -x hypr-dock > /dev/null 2>&1
                DOCK_VISIBLE=false
                HIDE_TIMER=0
            fi
        fi
    fi

    sleep "$SLEEP_TIME"
done