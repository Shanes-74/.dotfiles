#!/usr/bin/env bash

COLORS_FILE="$HOME/.config/hypr-dock/themes/lotos/colors.css"
SVG_DIR="$HOME/.config/hypr-dock/themes/lotos/point"

PRIMARY_COLOR=$(grep -oP '@define-color\s+primary\s+\K#[0-9a-fA-F]+' "$COLORS_FILE")

if [[ -z "$PRIMARY_COLOR" ]]; then
  echo "Erro: não encontrado 'primary'"
  exit 1
fi

echo "Usando cor: $PRIMARY_COLOR"

for file in "$SVG_DIR"/{1,2,3}.svg; do
  [[ -f "$file" ]] || continue

  echo "Atualizando $file"

  # 🎨 Cor
  sed -i -E "s/fill=\"[^\"]*\"/fill=\"$PRIMARY_COLOR\"/g" "$file"

  # 📏 Tamanho (seguro)
  if grep -q 'width=' "$file"; then
    sed -i -E 's/width="[^"]*"/width="12"/' "$file"
  else
    sed -i -E 's/<svg/<svg width="12"/' "$file"
  fi

  if grep -q 'height=' "$file"; then
    sed -i -E 's/height="[^"]*"/height="2"/' "$file"
  else
    sed -i -E 's/<svg/<svg height="2"/' "$file"
  fi
done

echo "Exito"