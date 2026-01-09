#!/usr/bin/env python3
import os
import hashlib
import subprocess
import multiprocessing
from pathlib import Path

# --- CONFIGURAÇÕES ---
USER = "shane"
WALL_DIR = Path(f"/home/{USER}/Imagens/Wallpapers")
THEME = Path(f"/home/{USER}/.config/scripts/wallpaper/wallmenu.rasi")
THUMB_DIR = Path(f"/home/{USER}/.cache/wallpaper-thumbs")

# Garante que o diretório de thumbs exista 
THUMB_DIR.mkdir(parents=True, exist_ok=True)

def gen_thumb(img_path):
    """Gera miniatura usando ImageMagick se não existir ou for antiga """
    img_path = Path(img_path)
    img_hash = hashlib.md5(str(img_path).encode()).hexdigest()
    thumb_path = THUMB_DIR / f"{img_hash.strip()}.jpg"

    # Verifica se precisa gerar (se não existe ou se a imagem original é mais nova) 
    if not thumb_path.exists() or img_path.stat().st_mtime > thumb_path.stat().st_mtime:
        cmd = [
            "convert", str(img_path),
            "-thumbnail", "400x400^",
            "-gravity", "center",
            "-extent", "400x400",
            str(thumb_path)
        ]
        subprocess.run(cmd, capture_output=True)
    return img_hash

def run_rofi(prompt, items, theme=None, extra_args=None):
    """Executa o Rofi e retorna a seleção """
    cmd = ["rofi", "-dmenu", "-p", prompt]
    if theme:
        cmd += ["-theme", str(theme)]
    if extra_args:
        cmd += extra_args
    
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    selected, _ = proc.communicate(input=items)
    return selected.strip()

def main():
    # 1. Seleção de Pasta 
    folders = sorted([f.name for f in WALL_DIR.iterdir() if f.is_dir()])
    if not folders:
        print("Nenhuma pasta de wallpapers encontrada.")
        return

    selected_folder = run_rofi("Selecione a Pasta", "\n".join(folders))
    if not selected_folder:
        return

    full_path = WALL_DIR / selected_folder

    # 2. Localizar imagens 
    extensions = {".jpg", ".jpeg", ".png", ".webp"}
    images = sorted([
        str(f) for f in full_path.iterdir() 
        if f.is_file() and f.suffix.lower() in extensions
    ])

    if not images:
        return

    # 3. Gerar thumbs em paralelo (usando todos os núcleos do processador) 
    with multiprocessing.Pool(multiprocessing.cpu_count()) as pool:
        pool.map(gen_thumb, images)

    # 4. Construção da lista para o Rofi com ícones 
    rofi_list = ""
    for img in images:
        img_name = os.path.basename(img)
        img_hash = hashlib.md5(img.encode()).hexdigest()
        thumb_path = THUMB_DIR / f"{img_hash}.jpg"
        rofi_list += f"{img_name}\0icon\x1f{thumb_path}\n"

    # 5. Seleção Final e Execução do walset 
    selected_img_name = run_rofi(
        "Selecione um Wallpaper", 
        rofi_list, 
        theme=THEME, 
        extra_args=["-show-icons"]
    )

    if selected_img_name:
        selected_full_path = full_path / selected_img_name
        # Chama o walset (certifique-se que o walset.py está no seu PATH) 
        subprocess.run(["walset", str(selected_full_path)])

if __name__ == "__main__":
    main()