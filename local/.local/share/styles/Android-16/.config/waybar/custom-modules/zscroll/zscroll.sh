#!/usr/bin/env bash

# ------------------------------------------------------------
# waybar-music.sh - Letreiro + capa giratória (polling)
# - Usa apenas magick (ImageMagick 7)
# - Polling a cada 0.5s para status e metadados
# - Rotação incremental com sleep (método clássico)
# - Múltiplas instâncias seguras (arquivos por PID)
# - JSON escapado com jq
# - Imagem padrão com furo transparente
# - Limpeza total ao sair
# - Imagem NUNCA é apagada em Paused (apenas em Stopped)
# ------------------------------------------------------------

# --- Configuração ---
PLAYER=""  # Deixe vazio para "auto" (player ativo). Ex: "spotify", "firefox"
CACHE_DIR="$HOME/.cache/waybar-music"
mkdir -p "$CACHE_DIR"

# Verifica se magick está disponível
if ! command -v magick &>/dev/null; then
    echo "ERRO: magick (ImageMagick 7) não encontrado." >&2
    exit 1
fi

# Arquivos por instância (baseados no PID)
PID=$$
LAST_URL_FILE="$CACHE_DIR/last_url_$PID.txt"
LAST_MUSIC_FILE="$CACHE_DIR/last_music_$PID.txt"
STATUS_FILE="$CACHE_DIR/status_$PID.txt"
ROTATION_PID_FILE="$CACHE_DIR/rotation_pid_$PID"
ROTATION_LOCK="$CACHE_DIR/rotation_lock_$PID"
TEMP_FILE="/tmp/waybar_zscroll_last_text_$$"

# Arquivos de imagem (compartilhados entre instâncias)
COVER_FILE="/tmp/waybar_cover.png"
BASE_COVER_FILE="/tmp/waybar_cover_base.png"

# --- Limpeza ---
cleanup() {
    # Mata o processo de rotação
    if [[ -f "$ROTATION_PID_FILE" ]]; then
        local rot_pid=$(cat "$ROTATION_PID_FILE" 2>/dev/null)
        kill "$rot_pid" 2>/dev/null
        rm -f "$ROTATION_PID_FILE"
    fi
    rm -f "$LAST_URL_FILE" "$LAST_MUSIC_FILE" "$STATUS_FILE" "$ROTATION_LOCK"

    # Mata o zscroll
    if [[ -n "$ZSCROLL_PID" ]]; then
        kill "$ZSCROLL_PID" 2>/dev/null
        wait "$ZSCROLL_PID" 2>/dev/null
    fi
    killall -f "zscroll" 2>/dev/null

    rm -f /tmp/waybar*.png
    rm -f "$TEMP_FILE"
    exit 0
}
trap cleanup SIGINT SIGQUIT SIGTERM EXIT

# --- Utilitários ---
# Escapa string para JSON (substitui aspas, barras, etc.)
json_escape() {
    printf '%s' "$1" | jq -Rsa .
}

# --- playerctl helpers ---
get_status() {
    playerctl status 2>/dev/null || echo "Stopped"
}

get_full_text() {
    local text=$(playerctl metadata --format "{{ title }} - {{ artist }}" 2>/dev/null)
    [[ -z "$text" ]] && echo "Nada tocando" || echo "${text//&/&amp;}"
}

get_title_only() {
    local title=$(playerctl metadata --format "{{ title }}" 2>/dev/null)
    [[ -z "$title" ]] && echo "Nada tocando" || echo "$title"
}

# --- Funções de imagem (apenas magick) ---
generate_default_cover() {
    local output="$1"
    local size=128
    local center=$((size / 2))

    magick -size "${size}x${size}" xc:transparent \
        -fill gray65 -draw "circle $center,$center $center,0" \
        -fill gray45 -draw "circle $center,$center $center,12" \
        -fill gray65 -draw "circle $center,$center $center,36" \
        -fill gray64 -draw "circle $center,$center $center,48" \
        "$output" 2>/dev/null
    magick "$output" -transparent gray64 "$output" 2>/dev/null
}

process_cover_base() {
    local input="$1" output="$2" size=128 radius=64
    [[ ! -s "$input" ]] && return 1

    local temp="/tmp/waybar_resized_$$.png"
    magick "$input" -resize "${size}x${size}^" -gravity center -extent "${size}x${size}" "$temp" 2>/dev/null
    [[ -f "$temp" ]] || { cp "$input" "$output"; return 0; }

    magick "$temp" \
        \( -size "${size}x${size}" xc:black -fill white -draw "circle $((size/2)),$((size/2)) $((size/2)),$((size-1))" \) \
        -alpha Off -compose CopyOpacity -composite "$output" 2>/dev/null

    if [[ -f "$output" ]]; then
        magick "$output" -fill gray64 -draw "circle $((size/2)),$((size/2)) $((size/2)),48" "$output" 2>/dev/null
        magick "$output" -transparent gray64 "$output" 2>/dev/null
    fi

    rm -f "$temp"
    [[ -s "$output" ]] && return 0 || return 1
}

# Garante que a imagem base exista (cria a padrão se faltar)
ensure_base_image() {
    if [[ ! -f "$BASE_COVER_FILE" ]]; then
        generate_default_cover "$BASE_COVER_FILE"
    fi
}

download_cover() {
    local url=$(playerctl metadata mpris:artUrl 2>/dev/null)
    if [[ -z "$url" ]]; then
        generate_default_cover "$BASE_COVER_FILE"
        cp "$BASE_COVER_FILE" "$COVER_FILE"
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
        else
            generate_default_cover "$BASE_COVER_FILE"
            cp "$BASE_COVER_FILE" "$COVER_FILE"
        fi
        rm -f "$tmp"
    fi
}

restore_base_image() {
    ensure_base_image  # garante que a base exista
    cp "$BASE_COVER_FILE" "$COVER_FILE"
}

# --- Rotação (método clássico: ângulo incremental com sleep) ---
start_rotation_daemon() {
    if [[ -f "$ROTATION_PID_FILE" ]]; then
        local old_pid=$(cat "$ROTATION_PID_FILE" 2>/dev/null)
        kill "$old_pid" 2>/dev/null
        rm -f "$ROTATION_PID_FILE"
    fi

    (
        local angle=0
        while true; do
            if [[ ! -f "$ROTATION_LOCK" ]]; then
                sleep 0.5
                continue
            fi

            local status=$(cat "$STATUS_FILE" 2>/dev/null)
            if [[ "$status" == "Playing" ]] && [[ -f "$BASE_COVER_FILE" ]]; then
                angle=$(( (angle + 4) % 360 ))
                magick "$BASE_COVER_FILE" -background transparent -rotate "$angle" \
                    -gravity center -extent 128x128 "$COVER_FILE" 2>/dev/null
            fi
            sleep 0.01667   # ~60 FPS
        done
    ) &
    local new_pid=$!
    echo "$new_pid" > "$ROTATION_PID_FILE"
}

stop_rotation_daemon() {
    if [[ -f "$ROTATION_PID_FILE" ]]; then
        local pid=$(cat "$ROTATION_PID_FILE" 2>/dev/null)
        kill "$pid" 2>/dev/null
        rm -f "$ROTATION_PID_FILE"
    fi
    rm -f "$ROTATION_LOCK"
    restore_base_image  # restaura a imagem base (garantindo que exista)
}

# --- zscroll (com after-text para reticências fixas) ---
start_zscroll() {
    if [[ -n "$ZSCROLL_PID" ]] && kill -0 "$ZSCROLL_PID" 2>/dev/null; then
        return
    fi
    killall -f "zscroll" 2>/dev/null

    get_scroll_text() {
        playerctl metadata --format "{{ title }}" 2>/dev/null || echo ""
    }
    export -f get_scroll_text

    zscroll --length 20 \
            --delay 0.18 \
            --match-command "playerctl status" \
            --match-text "Playing" "--scroll 1" \
            --match-text "Paused" "--scroll 0" \
            --update-check true \
            --after-text "..." \
            "bash -c get_scroll_text" 2>/dev/null | while IFS= read -r line; do
        if [[ -z "$line" ]]; then continue; fi
        local status=$(cat "$STATUS_FILE" 2>/dev/null)
        if [[ "$status" == "Playing" ]]; then
            local full_tooltip=$(playerctl metadata --format "{{ title }} - {{ artist }}" 2>/dev/null)
            [[ -z "$full_tooltip" ]] && full_tooltip="Nada tocando"
            full_tooltip="${full_tooltip//&/&amp;}"
            local escaped=$(printf '%s' "$line" | jq -Rsa .)
            echo "{\"text\":$escaped, \"class\":\"playing\", \"tooltip\":\"$full_tooltip\"}"
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
# Gera imagem base se não existir
ensure_base_image
cp "$BASE_COVER_FILE" "$COVER_FILE"

# Baixa capa inicial (se houver player)
download_cover

# Estado inicial
init_status=$(get_status)
init_title=$(get_title_only)
init_full=$(get_full_text)
echo "$init_status" > "$STATUS_FILE"

# Inicia daemon de rotação
start_rotation_daemon
touch "$ROTATION_LOCK"

if [[ "$init_status" == "Playing" ]]; then
    start_zscroll
elif [[ "$init_status" == "Paused" ]]; then
    short="${init_title:0:16}"
    [[ ${#init_title} -gt 16 ]] && short+="..."
    tooltip="${init_full//&/&amp;}"
    echo "{\"text\":\"$short\", \"class\":\"paused\", \"tooltip\":\"$tooltip\"}"
    restore_base_image
else
    # Stopped: remove imagens
    rm -f /tmp/waybar*.png
    echo "{\"text\":\"\", \"class\":\"stopped\", \"tooltip\":\"Nada tocando\"}"
fi

LAST_STATUS="$init_status"
LAST_MUSIC="$init_full"

# --- Loop de polling (0.5s) ---
while true; do
    sleep 0.5
    status=$(get_status)
    music=$(get_full_text)
    title=$(get_title_only)

    # Atualiza arquivo de status para o daemon de rotação
    echo "$status" > "$STATUS_FILE"

    # Se a música mudou, baixa nova capa (mesmo que esteja pausado)
    if [[ "$music" != "$LAST_MUSIC" ]]; then
        download_cover
        LAST_MUSIC="$music"
        # Se estiver pausado, atualiza o texto truncado também
        if [[ "$status" == "Paused" ]]; then
            short="${title:0:16}"
            [[ ${#title} -gt 16 ]] && short+="..."
            tooltip="${music//&/&amp;}"
            echo "{\"text\":\"$short\", \"class\":\"paused\", \"tooltip\":\"$tooltip\"}"
            restore_base_image
        fi
    fi

    # Gerencia zscroll e rotação com base no status
    if [[ "$status" == "Playing" ]]; then
        if [[ -z "$ZSCROLL_PID" ]] || ! kill -0 "$ZSCROLL_PID" 2>/dev/null; then
            start_zscroll
        fi
        # A rotação é gerenciada pelo daemon (lê STATUS_FILE)
    else
        if [[ -n "$ZSCROLL_PID" ]]; then
            stop_zscroll
        fi
        if [[ "$status" == "Paused" ]]; then
            # Restaura a imagem base (garante que exista)
            restore_base_image
            # Se o status mudou de Playing ou Stopped para Paused, emite JSON
            if [[ "$LAST_STATUS" != "Paused" ]]; then
                short="${title:0:16}"
                [[ ${#title} -gt 16 ]] && short+="..."
                tooltip="${music//&/&amp;}"
                echo "{\"text\":\"$short\", \"class\":\"paused\", \"tooltip\":\"$tooltip\"}"
            fi
        else # Stopped
            # Remove imagens apenas quando não há player
            rm -f /tmp/waybar*.png
            if [[ "$LAST_STATUS" != "Stopped" ]]; then
                echo "{\"text\":\"\", \"class\":\"stopped\", \"tooltip\":\"Nada tocando\"}"
            fi
        fi
    fi

    LAST_STATUS="$status"
done