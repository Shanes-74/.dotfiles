#!/usr/bin/env bash
# clipboard.sh — menu rofi para cliphist com suporte a imagens
# Deps obrigatórias : cliphist, rofi-wayland, wl-copy
# Deps para imagens : imagemagick (convert), file

# ─── Configuração ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_THEME="${CLIPHIST_ROFI_THEME:-$SCRIPT_DIR/clipboard.rasi}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-rofi"
NOTIF_ID_FILE="$CACHE_DIR/notif_id"   # persiste o ID entre execuções do script
MAX_IMG_ENTRIES=100
APP_NAME="Clipboard"

# ─── Utilitários ──────────────────────────────────────────────────────────────
die() {
    notify-send -a "$APP_NAME" -u critical "$APP_NAME" "$*" 2>/dev/null
    echo "ERRO: $*" >&2
    exit 1
}

has() { command -v "$1" &>/dev/null; }

check_deps() {
    local missing=()
    for cmd in cliphist rofi wl-copy; do
        has "$cmd" || missing+=("$cmd")
    done
    (( ${#missing[@]} )) && die "Dependências ausentes: ${missing[*]}"
}

# ─── Notificação única (substitui a anterior) ─────────────────────────────────
# Usa --replace-id para reutilizar a mesma notificação sempre.
# O ID retornado pelo notify-send é salvo em arquivo para persistir
# entre execuções do script.
notify() {
    local msg="$1"
    local urgency="${2:-normal}"
    local timeout="${3:-2000}"

    local replace_id=0
    [[ -f "$NOTIF_ID_FILE" ]] && replace_id=$(cat "$NOTIF_ID_FILE")

    local new_id
    new_id=$(notify-send \
        -a "$APP_NAME" \
        -u "$urgency" \
        -t "$timeout" \
        -r "$replace_id" \
        -p \
        "$APP_NAME" "$msg" 2>/dev/null)

    # Salva o novo ID se retornado (notify-send -p imprime o ID)
    [[ -n "$new_id" ]] && echo "$new_id" > "$NOTIF_ID_FILE"
}

# ─── Thumbnails ───────────────────────────────────────────────────────────────
mkdir -p "$CACHE_DIR"
find "$CACHE_DIR" -name 'thumb_*.png' -mtime +7 -delete &

make_thumb() {
    local id="$1"
    local thumb="$CACHE_DIR/thumb_${id}.png"
    local meta_file="$CACHE_DIR/meta_${id}"

    if [[ -f "$thumb" && -f "$meta_file" ]]; then
        echo "$thumb|$(cat "$meta_file")"
        return 0
    fi

    has convert || return 1

    local tmpfile mime
    tmpfile=$(mktemp)
    cliphist decode "$id" > "$tmpfile" 2>/dev/null || { rm -f "$tmpfile"; return 1; }
    mime=$(file --mime-type -b "$tmpfile" 2>/dev/null)

    if [[ "$mime" == image/* ]]; then
        local dimensions
        dimensions=$(identify -format "%wx%h" "$tmpfile" 2>/dev/null || echo "?x?")
        convert "$tmpfile" -thumbnail 256x256^ -gravity center -extent 256x256 "$thumb" 2>/dev/null
        rm -f "$tmpfile"
        if [[ -f "$thumb" ]]; then
            echo "${mime}|${dimensions}" > "$meta_file"
            echo "$thumb|${mime}|${dimensions}"
            return 0
        fi
    fi

    rm -f "$tmpfile"
    return 1
}

image_label() {
    local mime="$1"
    local dims="$2"
    local ext="${mime##*/}"
    ext="${ext^^}"
    case "$ext" in
        JPEG) ext="JPG" ;;
        SVG+XML) ext="SVG" ;;
        VND.MICROSOFT.ICON) ext="ICO" ;;
    esac
    echo "󰋩  ${ext}  ${dims/x/×}"
}

# ─── Monta entradas ───────────────────────────────────────────────────────────
build_entries() {
    local raw_entries img_count=0
    raw_entries=$(cliphist list 2>/dev/null) || die "Falha ao listar cliphist"
    [[ -z "$raw_entries" ]] && { notify "Histórico vazio"; exit 0; }

    IDS=(); LABELS=(); ICONS=()

    while IFS=$'\t' read -r id preview; do
        local label="$preview"
        local icon="edit-copy"

        if [[ "$preview" == *'[[ binary'* ]]; then
            if (( img_count < MAX_IMG_ENTRIES )); then
                local thumb_meta
                thumb_meta=$(make_thumb "$id")
                if [[ -n "$thumb_meta" ]]; then
                    local thumb mime dims
                    thumb="${thumb_meta%%|*}"
                    mime=$(echo "$thumb_meta" | cut -d'|' -f2)
                    dims=$(echo "$thumb_meta" | cut -d'|' -f3)
                    icon="$thumb"
                    label=$(image_label "$mime" "$dims")
                    (( img_count++ ))
                else
                    icon="package-x-generic"
                    label="󰈔  Binário"
                fi
            else
                icon="package-x-generic"
                label="󰈔  Binário"
            fi
        elif [[ "$preview" =~ ^https?:// ]]; then
            icon="insert-link"
        elif [[ "$preview" =~ ^\s*[\{\[] ]]; then
            icon="text-x-script"
        fi

        IDS+=("$id")
        LABELS+=("$label")
        ICONS+=("$icon")
    done <<< "$raw_entries"
}

# ─── Exibe o rofi ─────────────────────────────────────────────────────────────
show_menu() {
    local tmpinput
    tmpinput=$(mktemp)

    local n=${#LABELS[@]}
    for (( i=0; i<n; i++ )); do
        printf '%s\x00icon\x1f%s\n' "${LABELS[$i]}" "${ICONS[$i]}"
    done > "$tmpinput"

    local rofi_args=(
        -dmenu -i
        -p ""
        -kb-custom-1 "alt+d"
        -kb-custom-2 "super+alt+d"
        -kb-row-delete ""
        -mesg "Enter - Copiar     Alt+D - Deletar     Win+Alt+D - Limpar tudo     Esc - Sair"
        -format "i"
        -no-custom
        -show-icons
        -markup-rows
    )

    [[ -f "$ROFI_THEME" ]] && rofi_args+=(-theme "$ROFI_THEME")

    SELECTED_IDX=$(rofi "${rofi_args[@]}" < "$tmpinput")
    ROFI_EXIT=$?

    rm -f "$tmpinput"
}

# ─── Ações ────────────────────────────────────────────────────────────────────
action_copy() {
    cliphist decode "${IDS[$1]}" | wl-copy \
        && notify "Copiado para a área de transferência"
}

action_delete() {
    local idx="$1"
    rm -f "$CACHE_DIR/thumb_${IDS[$idx]}.png" "$CACHE_DIR/meta_${IDS[$idx]}" 2>/dev/null
    printf '%s\t%s' "${IDS[$idx]}" "${LABELS[$idx]}" | cliphist delete 2>/dev/null \
        && notify "Entrada removida do histórico"

    build_entries
    show_menu
    handle_action
}

action_clear_all() {
    cliphist wipe 2>/dev/null
    rm -f "$CACHE_DIR"/thumb_*.png "$CACHE_DIR"/meta_* 2>/dev/null
    notify "Histórico limpo"
}

# ─── Despacha ação ────────────────────────────────────────────────────────────
handle_action() {
    [[ -z "$SELECTED_IDX" || ! "$SELECTED_IDX" =~ ^[0-9]+$ ]] && exit 0

    case $ROFI_EXIT in
        0)  action_copy   "$SELECTED_IDX" ;;
        10) action_delete "$SELECTED_IDX" ;;
        11) action_clear_all ;;
        *)  exit 0 ;;
    esac
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    check_deps
    build_entries
    show_menu
    handle_action
}

main