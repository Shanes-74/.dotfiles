#!/bin/sh
# slurp.sh - Aplica cores do colors.json e repassa argumentos para o slurp
# ~/.config/scripts/slurp/slurp.sh

COLORS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/scripts/slurp/colors.json"

BG_DEFAULT="ffafd025"
BORDER_DEFAULT="ffafd0ff"
SEL_DEFAULT="f4dce400"

get_color() {
    key="$1"
    default="$2"
    color="$default"

    if [ -f "$COLORS_FILE" ] && command -v jq >/dev/null 2>&1; then
        val=$(jq -r ".$key" "$COLORS_FILE" 2>/dev/null)
        [ -n "$val" ] && [ "$val" != "null" ] && color="$val"
    fi

    color="${color#\#}"
    [ ${#color} -eq 6 ] && color="${color}ff"

    echo "$color"
}

bg=$(get_color "background" "$BG_DEFAULT")
border=$(get_color "border"    "$BORDER_DEFAULT")
sel=$(get_color "selection"    "$SEL_DEFAULT")

exec slurp -b "$bg" -c "$border" -s "$sel" -w 3 "$@"