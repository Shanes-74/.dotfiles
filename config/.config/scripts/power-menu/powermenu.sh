#!/usr/bin/env bash

lock=''
logout='󰈆'
reboot=''
shutdown=''
suspend='󰤁'
hibernate=''

rofi_cmd() {
    rofi -no-config -dmenu \
        -p "Power Menu" \
        -lines 2 \
        -columns 3 \
        -theme "~/.config/scripts/power-menu/powermenu.rasi"
}

run_rofi() {
    echo -e "$lock\n$logout\n$reboot\n$shutdown\n$suspend\n$hibernate" | rofi_cmd
}

chosen="$(run_rofi)"
[[ -z "$chosen" ]] && exit 0

case ${chosen} in
    $lock)      sleep 0.5 && hyprlock ;;
    $logout)    sleep 0.5 && hyprctl dispatch exit ;;
    $reboot)    sleep 0.5 && systemctl reboot ;;
    $shutdown)  sleep 0.5 && systemctl poweroff ;;
    $suspend)   sleep 0.5 && systemctl suspend ;;
    $hibernate) sleep 0.5 && systemctl hibernate ;;
esac