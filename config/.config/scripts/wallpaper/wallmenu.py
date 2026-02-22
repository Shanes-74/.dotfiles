#!/usr/bin/env python3

import os
import hashlib
import subprocess
import multiprocessing
from pathlib import Path


# --- CONFIG ---
USER = "shane"

WALL_DIR = Path(f"/home/{USER}/Imagens/Wallpapers")
THEME = Path(f"/home/{USER}/.config/scripts/wallpaper/wallmenu.rasi")
ROFI_THEME = Path(f"/home/{USER}/.config/rofi/rofi.rasi")
THUMB_DIR = Path(f"/home/{USER}/.cache/wallpaper-thumbs")

THUMB_DIR.mkdir(parents=True, exist_ok=True)


# --- HELPERS ---

def hash_path(path: Path) -> str:
    return hashlib.md5(str(path).encode()).hexdigest()


def gen_thumb(img_path: str):
    img_path = Path(img_path)
    img_hash = hash_path(img_path)
    thumb_path = THUMB_DIR / f"{img_hash}.jpg"

    if not thumb_path.exists() or img_path.stat().st_mtime > thumb_path.stat().st_mtime:
        cmd = [
            "convert", str(img_path),
            "-thumbnail", "400x400^",
            "-gravity", "center",
            "-extent", "400x400",
            str(thumb_path)
        ]
        subprocess.run(cmd, capture_output=True, check=True)

    return img_hash


def run_rofi(prompt, items, theme=None, extra_args=None):
    cmd = ["rofi", "-dmenu", "-p", prompt]

    if theme:
        cmd += ["-theme", str(theme)]

    if extra_args:
        cmd += extra_args

    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True
    )

    selected, _ = proc.communicate(input=items)
    return selected.strip()


# --- MAIN ---

def main():

    folders = sorted([f.name for f in WALL_DIR.iterdir() if f.is_dir()])

    if not folders:
        print("Nenhuma pasta encontrada.")
        return

    selected_folder = run_rofi(
        "Selecione a Pasta",
        "\n".join(folders),
        theme=ROFI_THEME,
        extra_args=["-i", "-matching", "fuzzy"]
    )

    if not selected_folder:
        return

    full_path = WALL_DIR / selected_folder

    extensions = {".jpg", ".jpeg", ".png", ".webp"}

    images = sorted([
        f for f in full_path.iterdir()
        if f.is_file() and f.suffix.lower() in extensions
    ])

    if not images:
        return

    # Pool limitado
    with multiprocessing.Pool(min(4, multiprocessing.cpu_count())) as pool:
        pool.map(gen_thumb, map(str, images))

    # Construção eficiente da lista
    entries = []

    for img in images:
        img_hash = hash_path(img)
        thumb_path = THUMB_DIR / f"{img_hash}.jpg"
        entries.append(f"{img.name}\0icon\x1f{thumb_path}")

    rofi_list = "\n".join(entries)

    selected_img_name = run_rofi(
        "Selecione um Wallpaper",
        rofi_list,
        theme=THEME,
        extra_args=["-show-icons"]
    )

    if selected_img_name:
        selected_full_path = full_path / selected_img_name
        subprocess.run(["walset", str(selected_full_path)], check=True)


if __name__ == "__main__":
    main()