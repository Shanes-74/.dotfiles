#!/usr/bin/env bash
# =============================================================================
#  install.sh — instala o .dotfiles (Hyprland + Matugen, só Arch) com GNU Stow
#
#  Funciona de qualquer pasta: ele descobre onde o repositório está e cria os
#  links relativos a partir daí. Também roda via curl:
#
#    curl -sL https://raw.githubusercontent.com/Shanes-74/.dotfiles/main/install.sh | bash
#
#  Uso: ./install.sh [opções]      (veja --help)
# =============================================================================
set -Eeuo pipefail

REPO_URL="${REPO_URL:-https://github.com/Shanes-74/.dotfiles.git}"

# Pastas do repo que o stow linka em $HOME (a mesma lista do stow.sh)
PACKAGES=(config local hyprland themes)

# Pasta onde o repo é clonado quando o script roda via curl (sobrescreva com DOTFILES_DEST=...)
DOTFILES_DEST="${DOTFILES_DEST:-$HOME/.dotfiles}"

TARGET_DIR="$HOME"
WALLPAPER_DIR="$HOME/Imagens/Wallpapers"   # caminho fixo no wallset

# -----------------------------------------------------------------------------
#  Dependências (edite à vontade)
#  Cada nome é procurado nos repositórios; o que não existir lá vai pro AUR.
#  O que não for encontrado em lugar nenhum é só listado no final.
# -----------------------------------------------------------------------------
REPO_PKGS=(
    # sessão
    hyprland hyprlock hypridle hyprsunset hyprpicker
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit-gnome
    # shell visual
    waybar rofi swaync swayosd awww nwg-dock-hyprland wlogout kitty
    # tema
    matugen imagemagick jq python python-pillow qt5ct qt6ct kvantum nwg-look
    # usados pelos scripts
    stow git rsync libnotify brightnessctl ddcutil playerctl
    grim slurp wl-clipboard cliphist
    thunar pavucontrol blueman btop cava micro
)
AUR_PKGS=(
    waybar-weather waybar-updates nmgui-git hyprmod-git   # do README original
    cursor-clip dotool wl-freeze                          # binds / apps do Hyprland
    bibata-cursor-theme whitesur-icon-theme               # cursor e ícones (settings.ini)
    ttf-google-sans ttf-geist-mono-nerd                   # fontes (kitty / gtk / qt)
)

# Plugins do Hyprland via hyprpm (só com --plugins): "url|nome"
HYPRPM_PLUGINS=(
    "https://github.com/hyprnux/hyprglass|hyprglass"
    "https://github.com/hyprwm/hyprland-plugins|hyprbars"
    "https://github.com/yayuuu/hyprland-scroll-overview|scrolloverview"
    "https://github.com/VirtCode/hypr-dynamic-cursors|dynamic-cursors"
    "https://github.com/micha4w/Hypr-DarkWindow|Hypr-DarkWindow"
    # gloview: repositório desconhecido — adicione aqui se quiser
)

# -----------------------------------------------------------------------------
#  Saída
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
    C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YLW=$'\033[1;33m'
    C_BLU=$'\033[0;34m'; C_OFF=$'\033[0m'
else
    C_RED=''; C_GRN=''; C_YLW=''; C_BLU=''; C_OFF=''
fi
info() { printf '%s==>%s %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok()   { printf '%s ok%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn() { printf '%s !!%s %s\n' "$C_YLW" "$C_OFF" "$*" >&2; }
die()  { printf '%s xx%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Uso: install.sh [opções]

  -y, --yes          não pergunta nada (pacman/AUR com --noconfirm)
  -n, --dry-run      mostra o que seria feito, sem alterar nada
      --skip-deps    não instala pacotes
      --skip-aur     instala só os pacotes dos repositórios oficiais
      --skip-theme   não gera o tema inicial (matugen)
      --skip-services não habilita os serviços systemd de usuário
      --plugins      instala os plugins do Hyprland via hyprpm
      --sddm         configura o tema de login SDDM (usa sudo)
      --uninstall    remove os links criados pelo stow
  -h, --help         esta ajuda
EOF
}

YES=0 DRY=0 SKIP_DEPS=0 SKIP_AUR=0 SKIP_THEME=0 SKIP_SERVICES=0 PLUGINS=0 SDDM=0 UNINSTALL=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes)        YES=1 ;;
        -n|--dry-run)    DRY=1 ;;
        --skip-deps)     SKIP_DEPS=1 ;;
        --skip-aur)      SKIP_AUR=1 ;;
        --skip-theme)    SKIP_THEME=1 ;;
        --skip-services) SKIP_SERVICES=1 ;;
        --plugins)       PLUGINS=1 ;;
        --sddm)          SDDM=1 ;;
        --uninstall)     UNINSTALL=1 ;;
        -h|--help)       usage; exit 0 ;;
        *) usage >&2; die "opção inválida: $arg" ;;
    esac
done

(( EUID != 0 )) || die "não rode como root — o script usa sudo só quando precisa."

run() {
    if (( DRY )); then
        printf '   [dry-run]'; printf ' %q' "$@"; printf '\n'
    else
        "$@"
    fi
}

have_tty() { { : </dev/tty; } 2>/dev/null; }

confirm() {   # confirm "pergunta"  → 0 = sim
    (( YES )) && return 0
    local ans
    if have_tty; then
        read -r -p "$1 [S/n] " ans </dev/tty || return 1
    else
        return 0
    fi
    [[ -z $ans || $ans =~ ^[sSyY] ]]
}

# -----------------------------------------------------------------------------
#  Localiza o repositório (ou clona, se rodou via curl)
# -----------------------------------------------------------------------------
locate_repo() {
    local self="${BASH_SOURCE[0]:-}"
    if [[ -n $self && -f $self ]]; then
        DOTFILES_DIR="$(cd "$(dirname "$self")" && pwd -P)"
        [[ -d $DOTFILES_DIR/hyprland && -d $DOTFILES_DIR/config ]] && return 0
    fi

    info "Repositório não encontrado ao lado do script — clonando em $DOTFILES_DEST"
    command -v git >/dev/null || { command -v pacman >/dev/null || die "instale o git e rode de novo."; run sudo pacman -S --needed --noconfirm git; }
    if [[ -d $DOTFILES_DEST/.git ]]; then
        run git -C "$DOTFILES_DEST" pull --ff-only
    else
        run git clone --depth 1 "$REPO_URL" "$DOTFILES_DEST"
    fi
    (( DRY )) && exit 0
    if have_tty; then
        exec bash "$DOTFILES_DEST/install.sh" "$@" </dev/tty
    fi
    exec bash "$DOTFILES_DEST/install.sh" "$@"
}

# -----------------------------------------------------------------------------
#  1. Dependências
# -----------------------------------------------------------------------------
MISSING_PKGS=()

install_deps() {
    command -v pacman >/dev/null || { warn "pacman não encontrado: pulando dependências (o setup é só Arch)."; return 0; }

    local repo=() aur=() p
    for p in "${REPO_PKGS[@]}" "${AUR_PKGS[@]}"; do
        pacman -Qq "$p" &>/dev/null && continue
        if pacman -Si "$p" &>/dev/null; then repo+=("$p"); else aur+=("$p"); fi
    done

    local noconfirm=()
    (( YES )) && noconfirm=(--noconfirm)

    if (( ${#repo[@]} )); then
        info "Instalando ${#repo[@]} pacotes dos repositórios: ${repo[*]}"
        run sudo pacman -S --needed "${noconfirm[@]}" "${repo[@]}" || warn "pacman terminou com erro — confira a saída acima."
    else
        ok "Pacotes oficiais já instalados."
    fi

    (( ${#aur[@]} )) || return 0
    if (( SKIP_AUR )); then
        warn "AUR ignorado (--skip-aur). Faltam: ${aur[*]}"
        return 0
    fi

    local helper=""
    command -v paru >/dev/null && helper=paru
    [[ -z $helper ]] && command -v yay >/dev/null && helper=yay
    if [[ -z $helper ]]; then
        warn "Nenhum helper do AUR (paru/yay) encontrado. Faltam: ${aur[*]}"
        return 0
    fi

    info "Pacotes para o AUR ($helper): ${aur[*]}"
    confirm "Instalar esses pacotes do AUR?" || { warn "AUR ignorado."; return 0; }
    for p in "${aur[@]}"; do
        if ! run "$helper" -S --needed "${noconfirm[@]}" "$p"; then
            MISSING_PKGS+=("$p")
        fi
    done
}

# -----------------------------------------------------------------------------
#  Links órfãos: links quebrados que apontam para dentro do repo (estrutura antiga).
#  O stow aborta ("cannot read directory") se encontra um desses no caminho.
# -----------------------------------------------------------------------------
clean_orphan_links() {
    local repo_name link dest removed=0
    repo_name="$(basename "$DOTFILES_DIR")"
    while IFS= read -r -d '' link; do
        dest="$(readlink "$link")"
        [[ $dest == *"$repo_name/"* ]] || continue
        warn "link órfão removido: ${link/#$HOME/\~} → $dest"
        run rm -- "$link"
        removed=$((removed + 1))
    done < <(find "$HOME/.config" "$HOME/.local" "$HOME/.themes" -xtype l -print0 2>/dev/null)
    (( removed )) || return 0
    ok "$removed link(s) órfão(s) removido(s)."
}

# -----------------------------------------------------------------------------
#  2. Conflitos: arquivos que já existem e não são o link do dotfiles
#     Primeiro varre tudo, depois pergunta (1 apagar / 2 .bak / 3 pular / 4 sair)
#     e só então aplica — assim "cancelar" não deixa nada pela metade.
# -----------------------------------------------------------------------------
C_STOWDIR=() C_PKG=() C_REL=() C_TARGET=() C_ACTION=()

scan_conflicts() {   # scan_conflicts <stow_dir> <pacote>
    local stow_dir="$1" pkg="$2" src rel target parent foreign
    while IFS= read -r -d '' src; do
        rel="${src#"$stow_dir/$pkg/"}"
        target="$TARGET_DIR/$rel"
        [[ -e $target || -L $target ]] || continue
        [[ "$(readlink -f "$target")" == "$(readlink -f "$src")" ]] && continue   # já é o link certo

        # se alguma pasta do caminho é um link para outro lugar, não mexe: deixa o stow reclamar
        foreign=0 parent="$(dirname "$target")"
        while [[ $parent != "$TARGET_DIR" && $parent != / ]]; do
            if [[ -L $parent ]]; then
                [[ "$(readlink -f "$parent")" == "$DOTFILES_DIR"/* ]] || foreign=1
                break
            fi
            parent="$(dirname "$parent")"
        done
        if (( foreign )); then
            warn "pasta-link externa, não vou mover: $target"
            continue
        fi

        C_STOWDIR+=("$stow_dir"); C_PKG+=("$pkg"); C_REL+=("$rel"); C_TARGET+=("$target"); C_ACTION+=("")
    done < <(find "$stow_dir/$pkg" \( -type f -o -type l \) -not -path '*/.git/*' -print0)
}

scan_all_conflicts() {
    local pkg
    for pkg in "${PACKAGES[@]}"; do
        [[ -d $DOTFILES_DIR/$pkg ]] && scan_conflicts "$DOTFILES_DIR" "$pkg"
    done
    scan_conflicts "$STYLES_DIR" "$CURRENT_STYLE"
}

# lê uma resposta do terminal (mesmo com o script vindo de um pipe)
ask() {   # ask "prompt" → resposta em $REPLY; retorna 1 se não der para ler
    REPLY=""
    have_tty || return 1
    read -r -p "$1" REPLY </dev/tty
}

action_label() {
    case "$1" in
        delete) echo "apagar" ;;
        bak)    echo "renomear para .bak" ;;
        skip)   echo "pular (manter o existente)" ;;
    esac
}

resolve_conflicts() {
    local total=${#C_TARGET[@]} i choice all_choice="" asked_all=0 answer
    (( total )) || { ok "Nenhum arquivo conflitante."; return 0; }

    warn "$total arquivo(s) conflitante(s) encontrado(s)."

    if (( DRY )); then
        for i in "${!C_TARGET[@]}"; do printf '   conflito: %s\n' "${C_TARGET[i]/#$HOME/\~}"; done
        echo "   [dry-run] na instalação real você escolhe o que fazer com cada um."
        return 0
    fi

    # sem terminal ou com --yes: não dá para perguntar → opção segura (renomear para .bak)
    if (( YES )) || ! have_tty; then
        warn "modo não interativo: conflitantes serão renomeados para .bak"
        for i in "${!C_TARGET[@]}"; do C_ACTION[i]=bak; done
        return 0
    fi

    # 1) só pergunta — nada é alterado enquanto você escolhe
    for i in "${!C_TARGET[@]}"; do
        if [[ -n $all_choice ]]; then C_ACTION[i]="$all_choice"; continue; fi

        printf '\n%sConflito (%d/%d):%s %s\n' "$C_YLW" $((i + 1)) "$total" "$C_OFF" "${C_TARGET[i]/#$HOME/\~}"
        echo "  1) Apagar o arquivo existente"
        echo "  2) Renomear para .bak e continuar"
        echo "  3) Pular (manter o existente, não aplicar o do dotfiles)"
        echo "  4) Cancelar toda a operação"
        while :; do
            choice=""
            ask "Escolha [1-4]: " && choice="$REPLY" || choice=4
            case "$choice" in
                1) C_ACTION[i]=delete; break ;;
                2) C_ACTION[i]=bak;    break ;;
                3) C_ACTION[i]=skip;   break ;;
                4) die "Operação cancelada. Nada foi alterado." ;;
                *) echo "  opção inválida" ;;
            esac
        done

        # a pergunta "aplicar a todos" aparece só depois da primeira escolha
        if (( ! asked_all )); then
            asked_all=1
            if (( i < total - 1 )) && ask "Aplicar essa escolha aos $((total - i - 1)) conflitos restantes? [s/N] " \
               && [[ $REPLY =~ ^[sSyY] ]]; then
                all_choice="${C_ACTION[i]}"
            fi
        fi
    done

    # 2) resumo e confirmação final antes de mexer em qualquer arquivo
    printf '\n%sResumo do que será feito:%s\n' "$C_BLU" "$C_OFF"
    for i in "${!C_TARGET[@]}"; do
        printf '  %-48s → %s\n' "${C_TARGET[i]/#$HOME/\~}" "$(action_label "${C_ACTION[i]}")"
    done
    if ask "Confirmar e continuar a instalação? [S/n] "; then answer="${REPLY:-s}"; else answer=n; fi
    [[ $answer =~ ^[sSyY] ]] || die "Operação cancelada. Nada foi alterado."
}

apply_conflict_actions() {
    local i target n
    for i in "${!C_TARGET[@]}"; do
        target="${C_TARGET[i]}"
        case "${C_ACTION[i]}" in
            delete)
                run rm -rf -- "$target"
                echo "   apagado:   ${target/#$HOME/\~}"
                ;;
            bak)
                n="$target.bak"
                while [[ -e $n || -L $n ]]; do n="$n.bak"; done   # já existe um .bak? empilha outro
                run mv -- "$target" "$n"
                echo "   renomeado: ${target/#$HOME/\~} → ${n/#$HOME/\~}"
                ;;
            skip)
                echo "   mantido:   ${target/#$HOME/\~}"   # o stow ignora esse arquivo (--ignore)
                ;;
        esac
    done
}

# argumentos --ignore do stow para os arquivos que o usuário escolheu pular
ignore_args() {   # ignore_args <stow_dir> <pacote>  → um argumento por linha
    local i esc
    for i in "${!C_TARGET[@]}"; do
        [[ ${C_ACTION[i]} == skip && ${C_STOWDIR[i]} == "$1" && ${C_PKG[i]} == "$2" ]] || continue
        esc="$(printf '%s' "${C_REL[i]}" | sed 's/[][\\.*^$+?(){}|\/]/\\&/g')"
        printf -- '--ignore=^%s$\n' "$esc"
    done
}

# -----------------------------------------------------------------------------
#  3. Caminhos fixos (/home/shane) → $HOME do usuário atual
# -----------------------------------------------------------------------------
fix_hardcoded_paths() {
    [[ $HOME == /home/shane ]] && return 0
    local files=() pkg
    for pkg in "${PACKAGES[@]}"; do
        mapfile -t -O "${#files[@]}" files < <(grep -rIl --exclude-dir=.git '/home/shane' "$DOTFILES_DIR/$pkg" 2>/dev/null || true)
    done
    (( ${#files[@]} )) || return 0
    info "Ajustando /home/shane → $HOME em ${#files[@]} arquivo(s) (veja 'git diff')"
    local esc="${HOME//\\/\\\\}"; esc="${esc//|/\\|}"; esc="${esc//&/\\&}"
    run sed -i "s|/home/shane|$esc|g" "${files[@]}"
}

# -----------------------------------------------------------------------------
#  4. Stow
# -----------------------------------------------------------------------------
STYLES_DIR=""
CURRENT_STYLE=""

resolve_style() {
    STYLES_DIR="$DOTFILES_DIR/local/.local/share/styles"
    CURRENT_STYLE="Android-16"
    if [[ -f $STYLES_DIR/.current_theme ]]; then
        CURRENT_STYLE="$(tr -d '[:space:]' < "$STYLES_DIR/.current_theme")"
    fi
    [[ -d $STYLES_DIR/$CURRENT_STYLE ]] || die "estilo '$CURRENT_STYLE' não existe em $STYLES_DIR"
}

stow_all() {
    command -v stow >/dev/null || die "stow não encontrado (pacman -S stow)."

    # pastas que recebem lixo de runtime (.wants do systemd, etc.) ficam reais,
    # para o stow não "dobrar" a pasta inteira para dentro do repositório
    run mkdir -p "$HOME/.config/systemd/user" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.cache/matugen"

    local pkg ign
    for pkg in "${PACKAGES[@]}"; do
        [[ -d $DOTFILES_DIR/$pkg ]] || { warn "pacote ausente: $pkg"; continue; }
        info "Stow: $pkg"
        mapfile -t ign < <(ignore_args "$DOTFILES_DIR" "$pkg")
        run stow -d "$DOTFILES_DIR" -t "$TARGET_DIR" "${ign[@]}" --restow "$pkg"
    done

    # o estilo ativo (waybar, rofi, swaync, swayosd, wlogout, dock) é um pacote stow à parte
    info "Stow: estilo $CURRENT_STYLE"
    mapfile -t ign < <(ignore_args "$STYLES_DIR" "$CURRENT_STYLE")
    run stow -d "$STYLES_DIR" -t "$TARGET_DIR" "${ign[@]}" --restow "$CURRENT_STYLE"
}

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
#  5. Ajustes pós-link
# -----------------------------------------------------------------------------
make_executable() {
    info "Garantindo permissão de execução nos scripts"
    run find "$DOTFILES_DIR/local/.local/bin" "$DOTFILES_DIR/config/.config/scripts" \
        "$DOTFILES_DIR/local/.local/share/styles" \
        -type f \( -path '*/bin/*' -o -name '*.sh' -o -name '*.py' \) ! -perm -u+x -exec chmod u+x {} +
    run find "$DOTFILES_DIR/config/.config/hooker" -type f ! -name '*.bak' ! -perm -u+x -exec chmod u+x {} +
}

install_wallpapers() {
    [[ -d $DOTFILES_DIR/Wallpapers ]] || return 0
    info "Copiando wallpapers para $WALLPAPER_DIR"
    run mkdir -p "$WALLPAPER_DIR"
    run cp -r --update=none "$DOTFILES_DIR/Wallpapers/." "$WALLPAPER_DIR/"   # cópia (o wallset usa find -type f, que ignora links)
}

ensure_path() {
    case ":$PATH:" in *":$HOME/.local/bin:"*) return 0 ;; esac
    grep -qs '>>> dotfiles PATH >>>' "$HOME/.profile" && return 0
    info "Adicionando ~/.local/bin ao PATH em ~/.profile"
    if (( DRY )); then echo "   [dry-run] append em ~/.profile"; return 0; fi
    {
        echo ''
        echo '# >>> dotfiles PATH >>>'
        # shellcheck disable=SC2016  # o $HOME deve ficar literal no ~/.profile
        echo 'export PATH="$HOME/.local/bin:$PATH"'
        echo '# <<< dotfiles PATH <<<'
    } >> "$HOME/.profile"
}

refresh_caches() {
    if command -v fc-cache >/dev/null; then
        run fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    fi
    if command -v gsettings >/dev/null && [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
        run gsettings set org.gnome.desktop.interface gtk-theme m3-gtk || true
    fi
}

# -----------------------------------------------------------------------------
#  6. Tema inicial (gera as cores que o Hyprland, Waybar, GTK, kitty... leem)
# -----------------------------------------------------------------------------
generate_theme() {
    if ! command -v matugen >/dev/null; then
        warn "matugen não instalado — rode 'wallset' depois para gerar as cores."
        return 0
    fi
    local state="$HOME/.cache/wallset/state.json" wp="" scheme="content" mode="dark"

    if [[ -f $state ]] && command -v jq >/dev/null; then
        wp="$(jq -r '.wallpaper // empty' "$state")"
        if [[ -f $wp ]]; then
            scheme="$(jq -r '.scheme // "content"' "$state")"
            mode="$(jq -r '.mode // "dark"' "$state")"
        else
            wp=""
        fi
    fi
    if [[ -z $wp ]]; then
        wp="$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | sed -n 1p)"
    fi
    [[ -n $wp ]] || { warn "nenhum wallpaper em $WALLPAPER_DIR — pulando o tema inicial."; return 0; }

    info "Gerando cores com matugen ($(basename "$wp"), scheme-$scheme, $mode)"
    # chamada direta (não via wallset): o wallset exige o awww-daemon rodando, que ainda não existe aqui
    run matugen -c "$HOME/.config/matugen/config.toml" image "$wp" -m "$mode" -t "scheme-$scheme" --source-color-index 0 \
        || { warn "matugen falhou — rode 'wallset' dentro do Hyprland."; return 0; }

    # estado que o 'wallset --reload' espera
    if (( ! DRY )) && command -v jq >/dev/null; then
        mkdir -p "$HOME/.cache/wallset"
        jq -n --arg wallpaper "$wp" --arg scheme "$scheme" --arg mode "$mode" \
            '{wallpaper: $wallpaper, scheme: $scheme, mode: $mode}' > "$state"
    fi
}

# -----------------------------------------------------------------------------
#  7. Serviços, plugins e SDDM
# -----------------------------------------------------------------------------
enable_services() {
    command -v systemctl >/dev/null || return 0
    info "Habilitando serviços de usuário (swaync, swayosd, theme)"
    if ! run systemctl --user daemon-reload 2>/dev/null; then
        warn "systemd --user indisponível agora. Depois rode: systemctl --user enable swaync swayosd theme"
        return 0
    fi
    run systemctl --user enable swaync.service swayosd.service theme.service \
        || warn "não consegui habilitar algum serviço."
}

install_plugins() {
    command -v hyprpm >/dev/null || { warn "hyprpm não encontrado (vem com o pacote hyprland)."; return 0; }
    info "Plugins do Hyprland (hyprpm) — precisa de cmake, meson, ninja, cpio, pkgconf e gcc"
    run hyprpm update || warn "hyprpm update falhou — tente de dentro do Hyprland."
    local entry url name
    for entry in "${HYPRPM_PLUGINS[@]}"; do
        url="${entry%%|*}"; name="${entry##*|}"
        run hyprpm add "$url" || warn "não consegui adicionar $url (já adicionado?)"
        run hyprpm enable "$name" || warn "não consegui habilitar $name"
    done
}

setup_sddm() {
    command -v sddm >/dev/null || { warn "sddm não instalado — pulando."; return 0; }
    info "Configurando o tema SDDM (sudo)"
    run sudo install -d -o "$USER" -g "$(id -gn)" /usr/share/sddm/themes/sddm-current
    run "$HOME/.local/bin/sddm-sync"
    run sudo install -d /etc/sddm.conf.d
    if (( DRY )); then
        echo "   [dry-run] gravar /etc/sddm.conf.d/10-theme.conf"
    else
        printf '[Theme]\nCurrent=sddm-current\n' | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
    fi
}

# -----------------------------------------------------------------------------
#  Desinstalar
# -----------------------------------------------------------------------------
uninstall() {
    command -v stow >/dev/null || die "stow não encontrado."
    resolve_style
    info "Removendo links do estilo $CURRENT_STYLE"
    run stow -d "$STYLES_DIR" -t "$TARGET_DIR" --delete "$CURRENT_STYLE"
    local pkg
    for pkg in "${PACKAGES[@]}"; do
        info "Removendo links: $pkg"
        run stow -d "$DOTFILES_DIR" -t "$TARGET_DIR" --delete "$pkg"
    done
    ok "Links removidos. Arquivos renomeados para .bak na instalação continuam onde estão."
}

# -----------------------------------------------------------------------------
#  Main
# -----------------------------------------------------------------------------
main() {
    locate_repo "$@"
    info "Repositório: $DOTFILES_DIR"
    info "Destino:     $TARGET_DIR"
    (( DRY )) && warn "modo dry-run: nada será alterado"

    if (( UNINSTALL )); then uninstall; exit 0; fi

    (( SKIP_DEPS )) || install_deps

    fix_hardcoded_paths
    resolve_style
    make_executable
    clean_orphan_links
    scan_all_conflicts
    resolve_conflicts
    apply_conflict_actions
    stow_all
    install_wallpapers
    ensure_path
    refresh_caches
    (( SKIP_THEME ))    || generate_theme
    (( SKIP_SERVICES )) || enable_services
    (( PLUGINS ))       && install_plugins
    (( SDDM ))          && setup_sddm

    if (( ${#MISSING_PKGS[@]} )); then
        warn "Não instalados (confira o nome no AUR): ${MISSING_PKGS[*]}"
    fi
    ok "Pronto. Faça logout e entre na sessão Hyprland."
    echo "   Trocar wallpaper/cores: wallset   |   Trocar estilo: ~/.config/scripts/styler/styler.sh"
}

main "$@"
