#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/waybar-clock-mode"
mode="time"
[[ -f "$STATE_FILE" ]] && mode="$(cat "$STATE_FILE")"

# texto principal
if [[ "$mode" == "date" ]]; then
    text=$(date '+%d/%m/%Y')
else
    text=$(date '+%H:%M')
fi

# tooltip por extenso (pt-BR)
tooltip=$(LC_TIME=pt_BR.UTF-8 date '+%A, %d de %B')

# escapa aspas para JSON
text=${text//\"/\\\"}
tooltip=${tooltip//\"/\\\"}

# saída JSON válida
printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"