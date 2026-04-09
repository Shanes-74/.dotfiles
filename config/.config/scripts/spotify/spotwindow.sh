#!/bin/bash

APP_COMMAND="spotify"
REAL_PROCESS="spotify"
HIDDEN_WS="special:magic_spotify"

die() { echo "Erro: $1" >&2; exit 1; }

is_running() { pgrep -x "$REAL_PROCESS" > /dev/null; }

get_window() {
    hyprctl clients -j | jq -r '
        first(.[] | select(.class == "Spotify" or .initialClass == "spotify"))
        | {address, workspace: .workspace.name}
        | @base64
    '
}

toggle_window() {
    local encoded addr spotify_ws current_ws

    encoded=$(get_window)
    [ -z "$encoded" ] && die "Janela não detectada. Spotify está rodando?"

    addr=$(echo "$encoded" | base64 -d | jq -r '.address')
    spotify_ws=$(echo "$encoded" | base64 -d | jq -r '.workspace')

    [ -z "$addr" ] || [ "$addr" = "null" ] && die "Endereço da janela inválido."

    if [ "$spotify_ws" = "$HIDDEN_WS" ]; then
        current_ws=$(hyprctl monitors -j | jq -r 'first(.[] | select(.focused)).activeWorkspace.id')
        hyprctl dispatch movetoworkspacesilent "$current_ws,address:$addr"
        hyprctl dispatch focuswindow "address:$addr"
    else
        hyprctl dispatch movetoworkspacesilent "$HIDDEN_WS,address:$addr"
    fi
}

if ! is_running; then
    echo "Iniciando Spotify..."
    exec $APP_COMMAND
fi

toggle_window