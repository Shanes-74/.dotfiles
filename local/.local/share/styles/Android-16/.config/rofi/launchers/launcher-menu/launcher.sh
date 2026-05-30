#!/bin/bash

# Categorias no formato: Nome|Ícone|Categorias_reais_(separadas por ;)
# Os nomes das categorias devem corresponder aos usados nos arquivos .desktop
categories=(
    "Todas|system-run|"
    "Aplicações|applications-other|Utility;Development;Office;Network;AudioVideo;Graphics;Education;"
    "Sistema|applications-system|System;Settings;"
    "Jogos|applications-games|Game;"
    "Desenvolvimento|applications-development|Development;"
    "Escritório|applications-office|Office;"
    "Internet|applications-internet|Network;"
    "Multimídia|applications-multimedia|AudioVideo;"
    "Configurações|preferences-system|Settings;"
)

# Monta entrada para o rofi -dmenu
menu=""
for cat in "${categories[@]}"; do
    IFS='|' read -r name icon catnames <<< "$cat"
    menu+="$name\x00icon\x1f$icon\n"
done

# Mostra seletor de categorias (usa o mesmo tema para manter o estilo)
selected=$(echo -e "$menu" | rofi -dmenu \
    -theme ~/.config/rofi/launchers/launcher-menu/launcher.rasi \
    -p "Categorias" -i)

[ -z "$selected" ] && exit 0

# Procura a categoria escolhida e executa o drun com filtro
for cat in "${categories[@]}"; do
    IFS='|' read -r name icon catnames <<< "$cat"
    if [ "$name" = "$selected" ]; then
        if [ -z "$catnames" ]; then
            # Todas as categorias
            rofi -show drun -theme ~/.config/rofi/launchers/launcher-menu/launcher.rasi
        else
            # Filtra pela categoria
            rofi -show drun -theme ~/.config/rofi/launchers/launcher-menu/launcher.rasi \
                -drun-categories "$catnames"
        fi
        exit 0
    fi
done

# Fallback (não deve acontecer)
rofi -show drun -theme ~/.config/rofi/launchers/launcher-menu/launcher.rasi