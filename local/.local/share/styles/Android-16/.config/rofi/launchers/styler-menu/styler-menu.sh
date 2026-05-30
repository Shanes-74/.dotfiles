#!/usr/bin/env bash

# ============================================================================
#  styler-menu.sh  —  Gerencia temas com Stow + Rofi (alvo = $HOME)
#  Além do Stow, edita ~/.config/hypr/modules/appearance.lua para alternar
#  o tema do Hyprland e recarrega o Hyprland.
# ============================================================================

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
readonly ICON_THEME=""
readonly ICON_WALLPAPER=""
readonly ICON_RELOAD=""
readonly ICON_SWITCH=""
readonly ICON_INSTALL=""
readonly ICON_HYPR=""

# ----------------------------------------------------------------------------
#  Configuração
# ----------------------------------------------------------------------------
STYLES_DIR="$HOME/.local/share/styles"
TARGET_DIR="$HOME"
STATE_FILE="$STYLES_DIR/.current_theme"
APPEARANCE_FILE="$HOME/.config/hypr/modules/appearance.lua"

# Resolve link simbólico se existir
if [ -L "$STYLES_DIR" ]; then
    STYLES_DIR=$(realpath "$STYLES_DIR")
fi

# ----------------------------------------------------------------------------
#  Função para atualizar o appearance.lua e recarregar o Hyprland
# ----------------------------------------------------------------------------
update_hypr_appearance() {
    local new_theme="$1"
    local old_theme="$2"   # pode ser vazio

    # Converte nomes para minúsculas (ex: "Android-14" -> "android-14")
    local new_theme_lower=$(echo "$new_theme" | tr '[:upper:]' '[:lower:]')
    local old_theme_lower=""
    [ -n "$old_theme" ] && old_theme_lower=$(echo "$old_theme" | tr '[:upper:]' '[:lower:]')

    # Garante que o diretório do arquivo existe
    mkdir -p "$(dirname "$APPEARANCE_FILE")"

    # Se o arquivo não existe, cria com a linha do novo tema descomentada
    if [ ! -f "$APPEARANCE_FILE" ]; then
        echo "require(\"modules.styles.${new_theme_lower}\")" > "$APPEARANCE_FILE"
        echo -e "${GREEN}${ICON_SUCCESS} Arquivo $APPEARANCE_FILE criado.${RESET}"
    else
        # Comenta a linha do tema antigo (se existir e estiver descomentada)
        if [ -n "$old_theme_lower" ]; then
            sed -i "s/^require(\"modules.styles.${old_theme_lower}\")$/--require(\"modules.styles.${old_theme_lower}\")/" "$APPEARANCE_FILE"
        fi

        # Descomenta a linha do novo tema (se estiver comentada)
        sed -i "s/^--require(\"modules.styles.${new_theme_lower}\")$/require(\"modules.styles.${new_theme_lower}\")/" "$APPEARANCE_FILE"

        # Se a linha ainda não existir (nem comentada nem descomentada), adiciona no final
        if ! grep -q "require(\"modules.styles.${new_theme_lower}\")" "$APPEARANCE_FILE" && ! grep -q "^--require(\"modules.styles.${new_theme_lower}\")" "$APPEARANCE_FILE"; then
            echo "require(\"modules.styles.${new_theme_lower}\")" >> "$APPEARANCE_FILE"
        fi
    fi

    # Recarrega o Hyprland (se o comando existir)
    if command -v hyprctl &>/dev/null; then
        echo -e "${BLUE}${ICON_HYPR} Recarregando Hyprland...${RESET}"
        hyprctl reload
    else
        echo -e "${YELLOW}${ICON_WARN} hyprctl não encontrado. Pule a recarga.${RESET}"
    fi
}

# ----------------------------------------------------------------------------
#  Verificações iniciais
# ----------------------------------------------------------------------------
if [ ! -d "$STYLES_DIR" ]; then
    echo -e "${RED}${ICON_ERROR} Diretório não encontrado: $STYLES_DIR${RESET}"
    exit 1
fi

if ! command -v rofi &>/dev/null; then
    echo -e "${RED}${ICON_ERROR} rofi não encontrado.${RESET}"
    exit 1
fi

# ----------------------------------------------------------------------------
#  Listar temas
# ----------------------------------------------------------------------------
mapfile -t themes < <(find "$STYLES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
if [ ${#themes[@]} -eq 0 ]; then
    echo -e "${YELLOW}${ICON_WARN} Nenhum tema encontrado.${RESET}"
    exit 0
fi

# ----------------------------------------------------------------------------
#  Tema atual
# ----------------------------------------------------------------------------
current_theme=""
if [ -f "$STATE_FILE" ]; then
    current_theme=$(cat "$STATE_FILE")
    [ ! -d "$STYLES_DIR/$current_theme" ] && current_theme=""
fi

# ----------------------------------------------------------------------------
#  Menu Rofi
# ----------------------------------------------------------------------------
selected=$(printf "%s\n" "${themes[@]}" | rofi -dmenu -p "${ICON_THEME} Tema atual: ${current_theme:-nenhum}" -i)

if [ -z "$selected" ]; then
    echo -e "${BLUE}${ICON_INFO} Cancelado.${RESET}"
    exit 0
fi

# ----------------------------------------------------------------------------
#  Função auxiliar para stow
# ----------------------------------------------------------------------------
do_stow() {
    local action_flag="$1"
    local pkg="$2"
    local msg="$3"
    echo -e "${CYAN}$msg $pkg${RESET}"
    ( cd "$STYLES_DIR" && stow $action_flag -t "$TARGET_DIR" "$pkg" )
}

# ----------------------------------------------------------------------------
#  Executar ação (instalar, restow, trocar)
# ----------------------------------------------------------------------------
ALL_OK=1
NEEDS_HYPR_UPDATE=0
NEW_THEME_FOR_HYPR=""

if [ -z "$current_theme" ]; then
    # Nenhum tema ativo → stow -S
    if do_stow "-S" "$selected" "${ICON_STOW} Instalando"; then
        echo "$selected" > "$STATE_FILE"
        echo -e "${GREEN}${ICON_SUCCESS} Tema $selected instalado.${RESET}"
        ALL_OK=0
        NEEDS_HYPR_UPDATE=1
        NEW_THEME_FOR_HYPR="$selected"
    else
        echo -e "${RED}${ICON_ERROR} Falha ao instalar $selected.${RESET}"
    fi
elif [ "$selected" = "$current_theme" ]; then
    # Mesmo tema → restow -R
    if do_stow "-R" "$selected" "${ICON_RESTOW} Reaplicando"; then
        echo -e "${GREEN}${ICON_SUCCESS} Tema $selected reaplicado.${RESET}"
        ALL_OK=0
        # Mesmo tema, apenas recarrega a aparência (já está descomentado)
        NEEDS_HYPR_UPDATE=1
        NEW_THEME_FOR_HYPR="$selected"
    else
        echo -e "${RED}${ICON_ERROR} Falha ao reaplicar $selected.${RESET}"
    fi
else
    # Tema diferente → remove atual, instala novo
    echo -e "${BLUE}${ICON_SWITCH} Trocando de $current_theme para $selected...${RESET}"
    if ( cd "$STYLES_DIR" && stow -D -t "$TARGET_DIR" "$current_theme" ) &&
       do_stow "-S" "$selected" "${ICON_INSTALL} Instalando $selected"; then
        echo "$selected" > "$STATE_FILE"
        echo -e "${GREEN}${ICON_SUCCESS} Troca concluída: $selected.${RESET}"
        ALL_OK=0
        NEEDS_HYPR_UPDATE=1
        NEW_THEME_FOR_HYPR="$selected"
    else
        echo -e "${RED}${ICON_ERROR} Falha na troca de temas.${RESET}"
    fi
fi

# ----------------------------------------------------------------------------
#  Atualizar o appearance.lua e recarregar Hyprland (se necessário)
# ----------------------------------------------------------------------------
if [ $ALL_OK -eq 0 ] && [ $NEEDS_HYPR_UPDATE -eq 1 ]; then
    update_hypr_appearance "$NEW_THEME_FOR_HYPR" "$current_theme"
fi

# ----------------------------------------------------------------------------
#  Integração com walset (regenerar cores)
# ----------------------------------------------------------------------------
if [ $ALL_OK -eq 0 ] && command -v walset &>/dev/null; then
    echo -e "${MAGENTA}${ICON_WALLPAPER} Regenerando cores...${RESET}"
    walset --reload && echo -e "${GREEN}${ICON_SUCCESS} Cores regeneradas.${RESET}" || echo -e "${RED}${ICON_ERROR} Falha no walset.${RESET}"
elif [ $ALL_OK -eq 0 ]; then
    echo -e "${YELLOW}${ICON_WARN} walset não instalado. Pule a regeneração de cores.${RESET}"
fi

# ----------------------------------------------------------------------------
#  Mensagem final
# ----------------------------------------------------------------------------
if [ $ALL_OK -eq 0 ]; then
    echo -e "${GREEN}${ICON_SUCCESS} Concluído.${RESET}"
else
    echo -e "${RED}${ICON_ERROR} Falha na operação.${RESET}"
    exit 1
fi