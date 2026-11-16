# My Hyprland M3Shell only Arch

Dotfiles do meu Hyprland (config em Lua) com tema Material 3 gerado pelo
[matugen](https://github.com/InioX/matugen) a partir do wallpaper. Tudo é
linkado com [GNU Stow](https://www.gnu.org/software/stow/).

## Instalação automática

    curl -sL https://raw.githubusercontent.com/Shanes-74/.dotfiles/main/install.sh | bash

Ou, com o repositório já clonado **em qualquer pasta**:

    git clone https://github.com/Shanes-74/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ./install.sh

O instalador: instala as dependências, move para `~/.dotfiles-backup/<data>/`
os arquivos que atrapalham, roda o stow, copia os wallpapers para
`~/Imagens/Wallpapers`, gera o tema inicial e habilita os serviços de usuário.

Opções úteis (`./install.sh --help`):

    -n, --dry-run     mostra o que seria feito
    -y, --yes         sem perguntas
        --skip-deps   não instala pacotes
        --skip-aur    só pacotes oficiais
        --plugins     instala os plugins do Hyprland (hyprpm)
        --sddm        configura o tema de login
        --uninstall   remove os links

## Dependências

### Pacotes do extra

    pacman -S --needed hyprland hyprlock hypridle hyprsunset hyprpicker kitty brightnessctl waybar rofi awww swaync swayosd stow imagemagick pavucontrol blueman thunar nwg-look python python-pillow qt5ct qt6ct kvantum jq rsync playerctl grim slurp wl-clipboard cliphist ddcutil matugen

### Pacotes do AUR (opcional)

    paru -S waybar-weather waybar-updates nmgui-git hyprmod-git cursor-clip dotool wl-freeze

A lista completa (com fontes, cursor e ícones) está no topo do `install.sh`.

## Estrutura

    .dotfiles/
    ├── config/      → ~/.config   (kitty, matugen, gtk, qt, Kvantum, systemd, scripts...)
    ├── hyprland/    → ~/.config/hypr
    ├── local/       → ~/.local    (bin: wallset, hooker, printshot...; fontes; estilos; SDDM)
    ├── themes/      → ~/.themes   (m3-gtk)
    ├── Wallpapers/
    ├── install.sh   instalador
    └── stow.sh      linka/remove/simula os pacotes acima

## Uso

    ./stow.sh          # cria os links
    ./stow.sh -r       # recria
    ./stow.sh -d       # remove
    ./stow.sh -n       # simula

    wallset                      # escolhe wallpaper e esquema de cores (rofi)
    wallset --reload             # reaplica o último tema
    ~/.config/scripts/styler/styler.sh   # troca o estilo (Android-14 / Android-16)

Os estilos ficam em `local/.local/share/styles/<nome>` e são pacotes stow
próprios (waybar, rofi, swaync, swayosd, wlogout, dock). O instalador linka o
estilo indicado em `.current_theme`.

## Atalhos principais

| Atalho | Ação |
| --- | --- |
| `SUPER + SPACE` | terminal (kitty) |
| `SUPER` (solto) | launcher (rofi) |
| `SUPER + V` | clipboard |
| `SUPER + SHIFT + W` | trocar wallpaper |
| `SUPER + L` | travar tela |
| `SUPER + CTRL + L` / `Power` | menu de energia |
| `SUPER + N` | luz noturna |
| `PRINT` / `SHIFT + PRINT` | captura (tela / região) |
| `ALT + TAB` | overview (scroll overview) |

Os demais estão em `hyprland/.config/hypr/modules/binds.lua`.
