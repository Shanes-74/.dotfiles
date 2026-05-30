#!/usr/bin/env bash

# ============================================================================
#  stow.sh  —  Stow para pacotes essenciais (config, local, hyprland)
#  Área de atuação: ~/.dotfiles/ (absoluto)
# ============================================================================

# ----------------------------------------------------------------------------
#  CONFIGURAÇÃO – Edite aqui as pastas que você quer stowar
# ----------------------------------------------------------------------------
PACKAGES=(
    "." "config"
    "." "local"
    "." "hyprland"
)

# ----------------------------------------------------------------------------
#  Diretórios absolutos
# ----------------------------------------------------------------------------
DOTFILES_DIR="$HOME/.dotfiles"
TARGET_DIR="$HOME"

# ----------------------------------------------------------------------------
#  Cores e Nerd Icons
# ----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

readonly ICON_SUCCESS=""
readonly ICON_ERROR=""
readonly ICON_WARN=""
readonly ICON_INFO=""
readonly ICON_STOW=""
readonly ICON_RESTOW=""
readonly ICON_DELETE=""
readonly ICON_CONFLICT=""
readonly ICON_CHECK=""

# ----------------------------------------------------------------------------
#  Processamento de opções
# ----------------------------------------------------------------------------
ACTION=""
SIMULATE=""
VERBOSE=""

while getopts "rdnv" opt; do
    case "$opt" in
        r) ACTION="-R" ;;
        d) ACTION="-D" ;;
        n) SIMULATE="-n" ;;
        v) VERBOSE="-v" ;;
        *) echo "Uso: $0 [-r|-d] [-n] [-v]"; exit 1 ;;
    esac
done

[ -z "$ACTION" ] && ACTION="-S"

case "$ACTION" in
    -D) MSG_ACTION="${ICON_DELETE} Deletando" ;;
    -R) MSG_ACTION="${ICON_RESTOW} Restowando" ;;
    -S) MSG_ACTION="${ICON_STOW} Stowando" ;;
esac

# ----------------------------------------------------------------------------
#  Verificação de conflitos
# ----------------------------------------------------------------------------
check_conflicts() {
    local subdir="$1"
    local pkg="$2"
    local stow_dir="$DOTFILES_DIR/$subdir"
    local stow_cmd="stow -n -t \"$TARGET_DIR\""
    [ -n "$VERBOSE" ] && stow_cmd="$stow_cmd $VERBOSE"

    output=$( ( cd "$stow_dir" && eval $stow_cmd "$pkg" 2>&1 ) )
    if echo "$output" | grep -q "would cause conflicts\|existing target is not owned by stow"; then
        echo "$output"
        return 0
    fi
    return 1
}

if [ -z "$SIMULATE" ]; then
    echo -e "${BLUE}${ICON_CHECK} Verificando conflitos...${RESET}"
    HAS_CONFLICT=0
    CONFLICT_DETAILS=""

    for ((i=0; i<${#PACKAGES[@]}; i+=2)); do
        subdir="${PACKAGES[i]}"
        pkg="${PACKAGES[i+1]}"
        conflicts=$(check_conflicts "$subdir" "$pkg")
        if [ $? -eq 0 ]; then
            HAS_CONFLICT=1
            CONFLICT_DETAILS+="\n${RED}${ICON_CONFLICT} Conflito em ${CYAN}$subdir/$pkg${RESET}:\n$conflicts\n"
        fi
    done

    if [ $HAS_CONFLICT -eq 1 ]; then
        echo -e "${RED}${ICON_ERROR} Abortando. Conflitos detectados:${RESET}$CONFLICT_DETAILS"
        exit 1
    fi
    echo -e "${GREEN}${ICON_SUCCESS} Nenhum conflito.${RESET}"
fi

# ----------------------------------------------------------------------------
#  Aplicar stow
# ----------------------------------------------------------------------------
stow_one() {
    local subdir="$1"
    local pkg="$2"
    local stow_dir="$DOTFILES_DIR/$subdir"

    if [ ! -d "$stow_dir/$pkg" ]; then
        echo -e "${YELLOW}${ICON_WARN} Pacote não encontrado: $stow_dir/$pkg${RESET}"
        return 1
    fi

    echo -e "${CYAN}$MSG_ACTION $subdir/$pkg${RESET}"
    ( cd "$stow_dir" && stow $SIMULATE $VERBOSE $ACTION -t "$TARGET_DIR" "$pkg" )
    return $?
}

ALL_OK=0
for ((i=0; i<${#PACKAGES[@]}; i+=2)); do
    subdir="${PACKAGES[i]}"
    pkg="${PACKAGES[i+1]}"
    if stow_one "$subdir" "$pkg"; then
        :
    else
        ALL_OK=1
    fi
done

if [ $ALL_OK -eq 0 ]; then
    echo -e "${GREEN}${ICON_SUCCESS} Concluído.${RESET}"
else
    echo -e "${RED}${ICON_ERROR} Algum pacote falhou.${RESET}"
    exit 1
fi