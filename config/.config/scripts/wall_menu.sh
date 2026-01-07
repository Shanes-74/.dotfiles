#!/usr/bin/env bash

WALLPAPER_DIR="${1:-$HOME/Imagens/Wallpapers}"
CACHE_DIR="$HOME/.cache/walselect"

[ -d "$WALLPAPER_DIR" ] || exit 1

mkdir -p "$CACHE_DIR"

# ───────── Thumbnails ─────────

for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
  [ -e "$img" ] || continue
  name="$(basename "$img")"
  thumb="$CACHE_DIR/$name.png"

  if [ ! -f "$thumb" ]; then
    magick "$img" \
      -resize 400x400^ \
      -gravity center \
      -extent 400x400 \
      -background none \
      "$thumb"
  fi
done

# ───────── Menu ─────────

selection=$(for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
  [ -e "$img" ] || continue
  name="$(basename "$img")"
  thumb="$CACHE_DIR/$name.png"
  echo -e "$name\0icon\x1f$thumb"
done | rofi -dmenu -show-icons \
    -theme ~/.config/rofi/wallmenu.rasi \
    -p "Wallpapers")

[ -z "$selection" ] && exit 0

walset "$WALLPAPER_DIR/$selection"
