#!/bin/bash
src=~/.cache/matugen/accela-colors.conf
dst="/home/shane/.config/Tachibana Labs/ACCELA.conf"

while IFS= read -r line; do
  [[ $line == *=* ]] || continue
  sed -i "s|^${line%%=*}=.*|$line|" "$dst"
done < "$src"
