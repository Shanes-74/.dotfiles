#!/usr/bin/env bash

# ============================================================================
#  stow.sh  —  Stow para pacotes essenciais (config, local, hyprland, themes)
#  Área de atuação: a pasta onde este script está (funciona em qualquer lugar)
# ============================================================================

# ----------------------------------------------------------------------------
#  CONFIGURAÇÃO – Edite aqui as pastas que você quer stowar
# ----------------------------------------------------------------------------
PACKAGES=(
    "." "config"
    "." "local"
    "." "hyprland"
    "." "themes"
)

# ----------------------------------------------------------------------------
#  Diretórios absolutos
# ----------------------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
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
readonly BOLD='\033[1m'
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
#  Função de ajuda
# ----------------------------------------------------------------------------
show_help() {
    printf "${BLUE}${ICON_INFO} stow.sh — Gerenciador de dotfiles${RESET}\n\n"
    printf "${BOLD}Uso:${RESET}\n"
    printf "  %s [OPÇÕES]\n\n" "$(basename "$0")"
    printf "${BOLD}Sem opções:${RESET}\n"
    printf "  Executa ${GREEN}stow${RESET} (cria links) para todos os pacotes listados em PACKAGES.\n\n"
    printf "${BOLD}Opções:${RESET}\n"
    printf "  ${GREEN}-r, --restow${RESET}    Recria os links (stow -R)\n"
    printf "  ${GREEN}-d, --delete${RESET}    Remove os links (stow -D)\n"
    printf "  ${GREEN}-n, --simulate${RESET}  Mostra o que seria feito (stow -n)\n"
    printf "  ${GREEN}-v, --verbose${RESET}   Exibe mais detalhes\n"
    printf "  ${GREEN}-h, --help${RESET}      Mostra esta ajuda\n\n"
    printf "${BOLD}Exemplos:${RESET}\n"
    printf "  ${CYAN}%s${RESET}         # Cria links\n" "$(basename "$0")"
    printf "  ${CYAN}%s -d${RESET}      # Remove links\n" "$(basename "$0")"
    printf "  ${CYAN}%s -r -v${RESET}   # Recria links com detalhes\n" "$(basename "$0")"
    printf "  ${CYAN}%s -n${RESET}      # Simula\n\n" "$(basename "$0")"
    printf "${BOLD}Pacotes gerenciados:${RESET} ${GREEN}"
    for ((i=1; i<${#PACKAGES[@]}; i+=2)); do
        printf "%s " "${PACKAGES[i]}"
    done
    printf "${RESET}\n"
}

# ----------------------------------------------------------------------------
#  Processamento de opções
# ----------------------------------------------------------------------------
ACTION=""
SIMULATE=""
VERBOSE=""

while getopts "rdnvh-" opt; do
    case "$opt" in
        r) ACTION="-R" ;;
        d) ACTION="-D" ;;
        n) SIMULATE="-n" ;;
        v) VERBOSE="-v" ;;
        h) show_help; exit 0 ;;
        -)
            case "${OPTARG}" in
                restow)   ACTION="-R" ;;
                delete)   ACTION="-D" ;;
                simulate) SIMULATE="-n" ;;
                verbose)  VERBOSE="-v" ;;
                help)     show_help; exit 0 ;;
                *) echo -e "${RED}${ICON_ERROR} Opção inválida: --${OPTARG}${RESET}"; exit 1 ;;
            esac
            ;;
        *) echo "Uso: $0 [-r|-d|-n|-v|-h]"; exit 1 ;;
    esac
done

[ -z "$ACTION" ] && ACTION="-S"

case "$ACTION" in
    -D) MSG_ACTION="${ICON_DELETE} Deletando" ;;
    -R) MSG_ACTION="${ICON_RESTOW} Restowando" ;;
    -S) MSG_ACTION="${ICON_STOW} Stowando" ;;
esac

# ----------------------------------------------------------------------------
#  Verificação de conflitos (apenas para stow e restow)
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

if [ -z "$SIMULATE" ] && [ "$ACTION" != "-D" ]; then
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
