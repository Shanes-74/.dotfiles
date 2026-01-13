#!/usr/bin/env python3
import os
import json
import subprocess
from pathlib import Path

CACHE_DIR = os.path.join(Path.home(), ".cache", "walset")
STATE_FILE = os.path.join(CACHE_DIR, "state.json")

def main():
    if not os.path.exists(STATE_FILE):
        print("Erro: Execute o walset primeiro para gerar o cache.")
        return

    with open(STATE_FILE, "r") as f:
        state = json.load(f)

    # Lê o estado que o walset salvou
    img = state.get("wallpaper")
    scm = state.get("scheme", "content")
    old_mode = state.get("mode", "dark")

    # Inverte a polaridade
    new_mode = "light" if old_mode == "dark" else "dark"

    # Reaplica usando o walset com os argumentos: imagem, esquema e NOVO modo
    # O walset se encarregará de rodar os hooks atualizados
    subprocess.run(["walset", img, scm, new_mode])

if __name__ == "__main__":
    main()