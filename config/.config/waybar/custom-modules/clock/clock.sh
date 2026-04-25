#!/usr/bin/env bash

# Arquivo de estado contendo o modo atual: "clock" ou "date"
STATE_FILE="$HOME/.cache/waybar-clock-mode"

# Se não existir, define modo padrão como "clock"
[[ -f "$STATE_FILE" ]] || echo "clock" > "$STATE_FILE"

# Se foi passado um argumento (ação de clique), atualiza o estado
if [[ $# -gt 0 ]]; then
    case "$1" in
        clock)
            echo "clock" > "$STATE_FILE"
            ;;
        date)
            echo "date" > "$STATE_FILE"
            ;;
        open)
            # Abre o aplicativo com base no modo atual
            mode=$(<"$STATE_FILE")
            if [[ "$mode" == "date" ]]; then
                gnome-calendar &> /dev/null &
            else
                gnome-clocks &> /dev/null &
            fi
            ;;
        *)
            echo "Uso: $0 [clock|date|open]" >&2
            exit 1
            ;;
    esac
    exit 0
fi

# Modo de exibição (sem argumentos): gera JSON para Waybar
mode=$(<"$STATE_FILE")

if [[ "$mode" == "date" ]]; then
    text=$(date '+%d/%m/%Y')
else
    text=$(date '+%H:%M')
fi

# Tooltip por extenso (pt-BR)
tooltip=$(LC_TIME=pt_BR.UTF-8 date '+%d de %B, %A')

# Escapar aspas para JSON
text=${text//\"/\\\"}
tooltip=${tooltip//\"/\\\"}

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"