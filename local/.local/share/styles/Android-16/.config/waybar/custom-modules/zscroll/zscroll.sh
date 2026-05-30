#!/usr/bin/env bash

# ------------------------------------------------------------
# Script singleton com zscroll + capa giratória (ANTI-HORÁRIA)
# - Playing: texto rolante (apenas título)
# - Paused: texto truncado (apenas título)
# - Tooltip: título e artista completos
# - Rotação anti-horária
# ------------------------------------------------------------

PIDFILE="/tmp/waybar-music-scroll.pid"
COVER_FILE="/tmp/waybar_cover.png"
BASE_COVER_FILE="/tmp/waybar_cover_base.png"
LAST_URL_FILE="/tmp/waybar_last_cover_url.txt"
LAST_MUSIC_FILE="/tmp/waybar_last_music.txt"
ROTATION_LOCK="/tmp/waybar_rotation_lock"
ROTATION_PID_FILE="/tmp/waybar_rotation.pid"

# --- Singleton ---
kill_previous() {
    if [[ -f "$PIDFILE" ]]; then
        local old_pid=$(cat "$PIDFILE" 2>/dev/null)
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            kill -TERM "$old_pid" 2>/dev/null
            sleep 0.2
            kill -KILL "$old_pid" 2>/dev/null
        fi
        rm -f "$PIDFILE"
    fi
}
kill_previous
echo $$ > "$PIDFILE"

cleanup() {
    if [[ -f "$ROTATION_PID_FILE" ]]; then
        kill "$(cat "$ROTATION_PID_FILE")" 2>/dev/null
        rm -f "$ROTATION_PID_FILE"
    fi
    rm -f "$PIDFILE" "$LAST_URL_FILE" "$LAST_MUSIC_FILE" "$ROTATION_LOCK"
    [[ -n "$ZSCROLL_PID" ]] && kill "$ZSCROLL_PID" 2>/dev/null
    rm -f "$TEMP_FILE"
    exit 0
}
trap cleanup SIGINT SIGQUIT SIGTERM EXIT

# --- playerctl helpers ---
# Para o zscroll (rolagem) – exibe APENAS o título
get_scroll_text() {
    playerctl metadata --format "{{ title }}" 2>/dev/null || echo ""
}
export -f get_scroll_text

# Para o tooltip e textos truncados – exibe título e artista
get_full_text() {
    local text=$(playerctl metadata --format "{{ title }} - {{ artist }}" 2>/dev/null)
    if [[ -z "$text" ]]; then
        echo "Nada tocando"
    else
        echo "${text//&/&amp;}"
    fi
}

# Apenas título para truncamento (quando pausado)
get_title_only() {
    local title=$(playerctl metadata --format "{{ title }}" 2>/dev/null)
    if [[ -z "$title" ]]; then
        echo "Nada tocando"
    else
        echo "${title//&/&amp;}"
    fi
}

get_status() {
    playerctl status 2>/dev/null || echo "Stopped"
}

truncate_text() {
    local text="$1" max_len=16
    if [[ ${#text} -le $max_len ]]; then
        echo "$text"
    else
        echo "${text:0:$max_len}..."
    fi
}

# --- Imagem: circular 128x128 ---
process_cover_base() {
    local input="$1" output="$2" size=128 radius=64
    [[ ! -s "$input" ]] && return 1
    command -v convert &>/dev/null || { cp "$input" "$output"; return 0; }
    local temp="/tmp/waybar_resized_$$.png"
    convert "$input" -resize "${size}x${size}^" -gravity center -extent "${size}x${size}" "$temp" 2>/dev/null
    [[ -f "$temp" ]] || { cp "$input" "$output"; return 0; }
    local mask="/tmp/waybar_mask_$$.png"
    convert -size "${size}x${size}" xc:black -fill white \
        -draw "circle $((size/2)),$((size/2)) $((size/2)),$((size-1))" "$mask" 2>/dev/null
    if [[ -f "$mask" ]]; then
        convert "$temp" "$mask" -alpha Off -compose CopyOpacity -composite "$output" 2>/dev/null
        rm -f "$mask"
    else
        mv "$temp" "$output"
    fi
    rm -f "$temp"
}

download_cover() {
    local url=$(playerctl metadata mpris:artUrl 2>/dev/null)
    if [[ -z "$url" ]]; then
        rm -f "$BASE_COVER_FILE" "$COVER_FILE" "$LAST_URL_FILE"
        return
    fi
    local last_url=$(cat "$LAST_URL_FILE" 2>/dev/null)
    if [[ "$url" != "$last_url" ]]; then
        local tmp="/tmp/waybar_cover_temp_$$.png"
        if [[ "$url" =~ ^file:// ]]; then
            cp "${url#file://}" "$tmp" 2>/dev/null
        else
            curl -s -o "$tmp" "$url" 2>/dev/null
        fi
        if [[ -s "$tmp" ]]; then
            process_cover_base "$tmp" "$BASE_COVER_FILE"
            cp "$BASE_COVER_FILE" "$COVER_FILE"
            echo "$url" > "$LAST_URL_FILE"
        fi
        rm -f "$tmp"
    fi
}

# --- Rotação anti-horária ---
start_rotation() {
    if [[ -f "$ROTATION_PID_FILE" ]]; then
        kill "$(cat "$ROTATION_PID_FILE")" 2>/dev/null
        rm -f "$ROTATION_PID_FILE"
    fi
    (
        local angle=0
        while true; do
            [[ ! -f "$ROTATION_LOCK" ]] && break
            if [[ -f "$BASE_COVER_FILE" ]]; then
                angle=$((angle + 5))
                convert "$BASE_COVER_FILE" -background transparent -rotate "$angle" \
                    -gravity center -extent 128x128 -alpha on "$COVER_FILE" 2>/dev/null
            fi
            sleep 0.02
        done
    ) &
    echo $! > "$ROTATION_PID_FILE"
}

stop_rotation() {
    if [[ -f "$ROTATION_PID_FILE" ]]; then
        kill "$(cat "$ROTATION_PID_FILE")" 2>/dev/null
        rm -f "$ROTATION_PID_FILE"
    fi
    rm -f "$ROTATION_LOCK"
    [[ -f "$BASE_COVER_FILE" ]] && cp "$BASE_COVER_FILE" "$COVER_FILE"
}

# --- Gerencia zscroll (apenas quando Playing) ---
start_zscroll() {
    if [[ -n "$ZSCROLL_PID" ]] && kill -0 "$ZSCROLL_PID" 2>/dev/null; then
        return
    fi
    killall -f "zscroll" 2>/dev/null
    zscroll --length 18 \
            --delay 0.15 \
            --match-command "playerctl status" \
            --match-text "Playing" "--scroll 1" \
            --match-text "Paused" "--scroll 0" \
            --update-check true \
            "bash -c get_scroll_text" 2>/dev/null | while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        # Só emite se o status atual for Playing
        if [[ "$(cat /tmp/waybar_current_status 2>/dev/null)" == "Playing" ]]; then
            full_tooltip=$(get_full_text)
            echo "{\"text\":\"$line\", \"class\":\"playing\", \"tooltip\":\"$full_tooltip\"}"
        fi
    done &
    ZSCROLL_PID=$!
}

stop_zscroll() {
    if [[ -n "$ZSCROLL_PID" ]]; then
        kill "$ZSCROLL_PID" 2>/dev/null
        unset ZSCROLL_PID
    fi
    killall -f "zscroll" 2>/dev/null
}

# --- Inicialização ---
TEMP_FILE="/tmp/waybar_zscroll_last_text_$$"
echo "" > "$TEMP_FILE"
download_cover

INIT_STATUS=$(get_status)
echo "$INIT_STATUS" > /tmp/waybar_current_status

if [[ "$INIT_STATUS" == "Playing" ]]; then
    start_zscroll
    touch "$ROTATION_LOCK"
    start_rotation
elif [[ "$INIT_STATUS" == "Paused" ]]; then
    title=$(get_title_only)
    short=$(truncate_text "$title")
    full_tooltip=$(get_full_text)
    echo "{\"text\":\"$short\", \"class\":\"paused\", \"tooltip\":\"$full_tooltip\"}"
else
    echo "{\"text\":\"\", \"class\":\"stopped\", \"tooltip\":\"Nada tocando\"}"
fi

LAST_STATUS="$INIT_STATUS"
LAST_MUSIC=$(get_full_text)

# --- Loop de monitoramento ---
while true; do
    sleep 0.5
    status=$(get_status)
    music=$(get_full_text)

    if [[ "$music" != "$LAST_MUSIC" ]]; then
        download_cover
        LAST_MUSIC="$music"
        if [[ "$status" == "Paused" ]]; then
            title=$(get_title_only)
            short=$(truncate_text "$title")
            echo "{\"text\":\"$short\", \"class\":\"paused\", \"tooltip\":\"$music\"}"
        fi
    fi

    echo "$status" > /tmp/waybar_current_status

    if [[ "$status" == "Playing" ]]; then
        if [[ ! -f "$ROTATION_LOCK" ]]; then
            touch "$ROTATION_LOCK"
            start_rotation
        fi
        if [[ -z "$ZSCROLL_PID" ]] || ! kill -0 "$ZSCROLL_PID" 2>/dev/null; then
            start_zscroll
        fi
    else
        if [[ -f "$ROTATION_LOCK" ]]; then
            stop_rotation
        fi
        if [[ -n "$ZSCROLL_PID" ]]; then
            stop_zscroll
        fi
    fi

    if [[ "$status" != "$LAST_STATUS" ]]; then
        if [[ "$status" == "Playing" ]]; then
            # O zscroll já emite, nada a fazer
            :
        elif [[ "$status" == "Paused" ]]; then
            title=$(get_title_only)
            short=$(truncate_text "$title")
            full_tooltip=$(get_full_text)
            echo "{\"text\":\"$short\", \"class\":\"paused\", \"tooltip\":\"$full_tooltip\"}"
        else
            echo "{\"text\":\"\", \"class\":\"stopped\", \"tooltip\":\"Nada tocando\"}"
        fi
        LAST_STATUS="$status"
    fi
done