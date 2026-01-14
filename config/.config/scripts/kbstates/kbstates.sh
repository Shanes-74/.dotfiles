#!/bin/bash

# Diretório para salvar o estado (em RAM para ser rápido)
STATE_DIR="/tmp/kbstates"
mkdir -p "$STATE_DIR"

# Arquivos de estado
CAPS_STATE_FILE="$STATE_DIR/caps_state"
NUM_STATE_FILE="$STATE_DIR/num_state"

# Ícones
ICON_CAPS_ON="caps-lock-on"
ICON_CAPS_OFF="caps-lock-off"
ICON_NUM_ON="num-lock-on"
ICON_NUM_OFF="num-lock-off"

# Inicializa os arquivos se não existirem (baseado no estado atual real)
if [ ! -f "$CAPS_STATE_FILE" ]; then
    brightnessctl --device='*::capslock' get > "$CAPS_STATE_FILE"
fi
if [ ! -f "$NUM_STATE_FILE" ]; then
    brightnessctl --device='*::numlock' get > "$NUM_STATE_FILE"
fi

case $1 in
    caps)
        CURRENT=$(cat "$CAPS_STATE_FILE")
        if [ "$CURRENT" -eq "0" ]; then
            swayosd-client --custom-message "Caps Lock: On" --custom-icon "$ICON_CAPS_ON"
            echo "1" > "$CAPS_STATE_FILE"
        else
            swayosd-client --custom-message "Caps Lock: Off" --custom-icon "$ICON_CAPS_OFF"
            echo "0" > "$CAPS_STATE_FILE"
        fi
        ;;
    num)
        CURRENT=$(cat "$NUM_STATE_FILE")
        if [ "$CURRENT" -eq "0" ]; then
            swayosd-client --custom-message "Num Lock: On" --custom-icon "$ICON_NUM_ON"
            echo "1" > "$NUM_STATE_FILE"
        else
            swayosd-client --custom-message "Num Lock: Off" --custom-icon "$ICON_NUM_OFF"
            echo "0" > "$NUM_STATE_FILE"
        fi
        ;;
esac