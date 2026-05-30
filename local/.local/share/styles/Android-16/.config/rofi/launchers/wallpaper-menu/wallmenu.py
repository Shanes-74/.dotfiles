#!/usr/bin/env python3

import hashlib
import subprocess
from multiprocessing.pool import ThreadPool
from pathlib import Path
import os


# --- CONFIG ---
WALL_DIR = Path("~/Imagens/Wallpapers").expanduser()
THEME = Path("~/.config/scripts/wallpaper/wallmenu.rasi").expanduser()
ROFI_THEME = Path("~/.config/rofi/rofi.rasi").expanduser()
THUMB_DIR = Path("~/.cache/wallpaper-thumbs").expanduser()

THUMB_DIR.mkdir(parents=True, exist_ok=True)

EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

# tamanho maior das thumbnails
THUMB_SIZE = 400


# --- HELPERS ---

def hash_path(path: Path) -> str:
    return hashlib.sha1(str(path).encode()).hexdigest()


def gen_thumb(img: Path):
    img_hash = hash_path(img)
    thumb = THUMB_DIR / f"{img_hash}.jpg"

    try:
        if thumb.exists() and thumb.stat().st_mtime >= img.stat().st_mtime:
            return img, thumb

        subprocess.run(
            [
                "convert",
                str(img),
                "-thumbnail", f"{THUMB_SIZE}x{THUMB_SIZE}^",
                "-gravity", "center",
                "-extent", f"{THUMB_SIZE}x{THUMB_SIZE}",
                str(thumb),
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )

    except Exception:
        return None

    return img, thumb


# --- ROFI ---

def run_rofi(items: str, theme: Path, extra=None):
    cmd = ["rofi", "-dmenu"]

    if theme:
        cmd += ["-theme", str(theme)]

    if extra:
        cmd += extra

    result = subprocess.run(cmd, input=items, text=True, capture_output=True)
    return result.stdout.strip()


# --- MAIN ---

def main():

    if not WALL_DIR.exists():
        return

    folders = sorted(f.name for f in WALL_DIR.iterdir() if f.is_dir())
    if not folders:
        return

    selected_folder = run_rofi(
        "\n".join(folders),
        ROFI_THEME,
        ["-i", "-matching", "fuzzy"]
    )

    if not selected_folder:
        return

    folder = WALL_DIR / selected_folder

    images = [
        f for f in folder.iterdir()
        if f.suffix.lower() in EXTENSIONS and f.is_file()
    ]

    if not images:
        return

    workers = min(4, os.cpu_count())

    with ThreadPool(workers) as pool:
        results = pool.map(gen_thumb, images)

    entries = []
    path_map = {}

    for r in results:
        if not r:
            continue

        img, thumb = r
        entries.append(f"{img.name}\0icon\x1f{thumb}")
        path_map[img.name] = img

    if not entries:
        return

    selected = run_rofi(
        "\n".join(entries),
        THEME,
        ["-show-icons", "-no-config"]
    )

    if selected in path_map:
        subprocess.run(["walset", str(path_map[selected])])


if __name__ == "__main__":
    main()