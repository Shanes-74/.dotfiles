#!/usr/bin/env bash

# ============================================================================
#  stow.sh  —  Stow para pacotes essenciais (config, local, hyprland, themes)
#  Sempre simula antes: se algo falhar, nada é aplicado e o problema é apontado.
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
    printf "  Simula e, se tudo estiver certo, executa ${GREEN}stow${RESET} (cria links) para todos os pacotes de PACKAGES.\n"
    printf "  Se a simulação achar qualquer problema, ${RED}nada é aplicado${RESET} e os problemas são listados.\n\n"
    printf "${BOLD}Opções:${RESET}\n"
    printf "  ${GREEN}-r, --restow${RESET}    Recria os links (stow -R)\n"
    printf "  ${GREEN}-d, --delete${RESET}    Remove os links (stow -D)\n"
    printf "  ${GREEN}-v, --verbose${RESET}   Exibe mais detalhes\n"
    printf "  ${GREEN}-h, --help${RESET}      Mostra esta ajuda\n\n"
    printf "${BOLD}Exemplos:${RESET}\n"
    printf "  ${CYAN}%s${RESET}         # Cria links\n" "$(basename "$0")"
    printf "  ${CYAN}%s -d${RESET}      # Remove links\n" "$(basename "$0")"
    printf "  ${CYAN}%s -r -v${RESET}   # Recria links com detalhes\n" "$(basename "$0")"
    printf "\n"
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
VERBOSE=""

while getopts "rdvh-" opt; do
    case "$opt" in
        r) ACTION="-R" ;;
        d) ACTION="-D" ;;
        v) VERBOSE="-v" ;;
        h) show_help; exit 0 ;;
        -)
            case "${OPTARG}" in
                restow)   ACTION="-R" ;;
                delete)   ACTION="-D" ;;
                verbose)  VERBOSE="-v" ;;
                help)     show_help; exit 0 ;;
                *) echo -e "${RED}${ICON_ERROR} Opção inválida: --${OPTARG}${RESET}"; exit 1 ;;
            esac
            ;;
        *) echo "Uso: $0 [-r|-d|-v|-h]"; exit 1 ;;
    esac
done

[ -z "$ACTION" ] && ACTION="-S"

case "$ACTION" in
    -D) MSG_ACTION="${ICON_DELETE} Deletando" ;;
    -R) MSG_ACTION="${ICON_RESTOW} Restowando" ;;
    -S) MSG_ACTION="${ICON_STOW} Stowando" ;;
esac

# ----------------------------------------------------------------------------
#  Agrupa os pacotes por pasta: um único stow por pasta = um plano só, e o stow
#  checa todos os pacotes juntos antes de mexer em qualquer coisa.
# ----------------------------------------------------------------------------
declare -A PKG_GROUPS
GROUP_ORDER=()
PROBLEMS=()

for ((i=0; i<${#PACKAGES[@]}; i+=2)); do
    subdir="${PACKAGES[i]}"
    pkg="${PACKAGES[i+1]}"
    if [ ! -d "$DOTFILES_DIR/$subdir/$pkg" ]; then
        PROBLEMS+=("${RED}${ICON_WARN} Pacote não encontrado:${RESET} $DOTFILES_DIR/$subdir/$pkg")
        continue
    fi
    [ -z "${PKG_GROUPS[$subdir]+x}" ] && GROUP_ORDER+=("$subdir")
    PKG_GROUPS[$subdir]+="$pkg "
done

run_stow() {   # run_stow <1=simular|0=aplicar> <subdir>  → saída do stow; retorna o status dele
    local sim="$1" subdir="$2" flag="" pkgs
    read -ra pkgs <<< "${PKG_GROUPS[$subdir]}"
    [ "$sim" -eq 1 ] && flag="-n"
    ( cd "$DOTFILES_DIR/$subdir" && stow $flag $VERBOSE $ACTION -t "$TARGET_DIR" "${pkgs[@]}" 2>&1 )
}

format_stow_output() {   # destaca o que o stow reportou
    local line
    while IFS= read -r line; do
        case "$line" in
            ""|"All operations aborted."|*"in simulation mode"*) ;;
            *ERROR*)  echo -e "   ${RED}${ICON_ERROR} ${line}${RESET}" ;;
            *"* "*)   echo -e "   ${RED}${ICON_CONFLICT}${RESET} ${line#*\* }" ;;
            *)        echo -e "   ${YELLOW}${line}${RESET}" ;;
        esac
    done
}

# ----------------------------------------------------------------------------
#  Fase 1 — simulação (nada é alterado)
# ----------------------------------------------------------------------------
echo -e "${BLUE}${ICON_CHECK} Simulando antes de aplicar...${RESET}"

for subdir in "${GROUP_ORDER[@]}"; do
    out="$(run_stow 1 "$subdir")"
    rc=$?
    if [ $rc -ne 0 ] || printf '%s\n' "$out" | grep -qE 'ERROR|would cause conflicts'; then
        PROBLEMS+=("${RED}${ICON_CONFLICT} Problemas ao stowar:${RESET} ${CYAN}${PKG_GROUPS[$subdir]% }${RESET}
$(printf '%s\n' "$out" | format_stow_output)")
    else
        # avisos que não impedem (ex.: link absoluto ignorado)
        printf '%s\n' "$out" | grep -i 'ignoring' | while IFS= read -r line; do
            echo -e "   ${YELLOW}${ICON_WARN} ${line}${RESET}"
        done
    fi
done

if [ ${#PROBLEMS[@]} -gt 0 ]; then
    echo -e "\n${RED}${ICON_ERROR} A simulação falhou — NADA foi aplicado.${RESET}\n"
    for p in "${PROBLEMS[@]}"; do
        echo -e "$p\n"
    done
    echo -e "${YELLOW}Resolva os itens acima e rode ./$(basename "$0") de novo. (O ./install.sh pergunta o que fazer com arquivos conflitantes.)${RESET}"
    exit 1
fi
echo -e "${GREEN}${ICON_SUCCESS} Simulação sem erros.${RESET}"

# ----------------------------------------------------------------------------
#  Fase 2 — aplicação de verdade
# ----------------------------------------------------------------------------
APPLIED=()
for subdir in "${GROUP_ORDER[@]}"; do
    echo -e "${CYAN}$MSG_ACTION ${PKG_GROUPS[$subdir]% }${RESET}"
    out="$(run_stow 0 "$subdir")"
    rc=$?
    [ -n "$VERBOSE" ] && printf '%s\n' "$out"
    if [ $rc -ne 0 ]; then
        echo -e "${RED}${ICON_ERROR} Falha inesperada ao aplicar em ${CYAN}$subdir${RESET}:"
        printf '%s\n' "$out" | format_stow_output
        [ ${#APPLIED[@]} -gt 0 ] && echo -e "${YELLOW}Já aplicados antes da falha: ${APPLIED[*]}${RESET}"
        exit 1
    fi
    APPLIED+=("$subdir")
done

echo -e "${GREEN}${ICON_SUCCESS} Concluído.${RESET}"
