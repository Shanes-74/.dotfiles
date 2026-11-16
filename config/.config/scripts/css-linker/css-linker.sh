#!/bin/bash
# ~/.config/scripts/css-linker/css-linker.sh

CENTRAL="$HOME/.cache/matugen/colors.css"

DESTINOS=(
	"$HOME/.config/waybar/"
    "$HOME/.config/swaync/"
    "$HOME/.config/swayosd/"
    #"$HOME/.config/hypr-dock/themes/lotos/"
    "$HOME/.config/wlogout/"
    "$HOME/.config/nwg-dock-hyprland/"
)

erro=0

for dest in "${DESTINOS[@]}"; do
    mkdir -p "$(dirname "$dest")"
    if ln -sf "$CENTRAL" "$dest" 2>/dev/null; then
        echo "Link criado: $dest -> $CENTRAL"
    else
        echo "Erro ao criar link: $dest"
        erro=1
    fi
done

if [ $erro -eq 0 ]; then
    echo "Todos os links configurados com sucesso."
    # Opcional: notificação de sucesso
    # notify-send "CSS Linker" "Links atualizados"
else
    notify-send -u critical "CSS Linker" "Erro ao criar alguns links"
    exit 1
fi
