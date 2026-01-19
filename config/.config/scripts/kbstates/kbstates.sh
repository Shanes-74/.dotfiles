#!/bin/bash

# Delay necessário para o kernel atualizar o estado do LED após input
LED_DELAY=0.128
ICON_CAPS_ON="caps-lock-on"
ICON_CAPS_OFF="caps-lock-off"
ICON_NUM_ON="num-lock-on"
ICON_NUM_OFF="num-lock-off"

read_led() {
    tr -d '\n[:space:]' < "$1"
}

show_state() {
    local NAME="$1"
    local FILE="$2"
    local ICON_ON="$3"
    local ICON_OFF="$4"

    sleep "$LED_DELAY"

    STATE=$(read_led "$FILE")

    if [ "$STATE" = "1" ]; then
        swayosd-client --custom-message "$NAME: On" --custom-icon "$ICON_ON"
    else
        swayosd-client --custom-message "$NAME: Off" --custom-icon "$ICON_OFF"
    fi
}

case "$1" in
    caps)
        show_state "Caps Lock" \
            "/sys/class/leds/input3::capslock/brightness" \
            "$ICON_CAPS_ON" "$ICON_CAPS_OFF"
        ;;
    num)
        show_state "Num Lock" \
            "/sys/class/leds/input3::numlock/brightness" \
            "$ICON_NUM_ON" "$ICON_NUM_OFF"
        ;;
esac