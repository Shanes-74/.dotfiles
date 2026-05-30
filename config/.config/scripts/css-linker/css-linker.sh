#!/bin/bash
# ~/.config/scripts/css-linker/css-linker.sh

CENTRAL="$HOME/.cache/matugen/colors/colors.css"

DESTINOS=(
    "$HOME/.config/waybar/colors.css"
    "$HOME/.config/swaync/colors.css"
    "$HOME/.config/swayosd/colors.css"
    "$HOME/.config/hypr-dock/themes/lotos/colors.css"
    "$HOME/.config/wlogout/colors.css"
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