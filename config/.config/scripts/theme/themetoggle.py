#!/usr/bin/env python3
import os
import json
import subprocess
from pathlib import Path

# --- CONFIGURAÇÕES ---
CACHE_DIR = os.path.join(Path.home(), ".cache", "walset")
STATE_FILE = os.path.join(CACHE_DIR, "state.json")

def set_icon_theme(mode):
    """Altera o tema de ícones via gsettings"""
    # Define o nome exato dos temas conforme você solicitou
    icon_theme = "Tela-circle-black-dark" if mode == "dark" else "Tela-circle-black-light"
    
    try:
        # Altera para GTK (aplicativos como Nautilus, Thunar, etc)
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", icon_theme], check=False)
        print(f"Ícones alterados para: {icon_theme}")
    except Exception as e:
        print(f"Erro ao mudar ícones: {e}")

def main():
    if not os.path.exists(STATE_FILE):
        print("Erro: Execute o walset primeiro para gerar o cache.")
        return

    with open(STATE_FILE, "r") as f:
        state = json.load(f)

    # Lê o estado atual
    img = state.get("wallpaper")
    scm = state.get("scheme", "content")
    old_mode = state.get("mode", "dark")

    # Inverte o modo
    new_mode = "light" if old_mode == "dark" else "dark"

    # 1. Altera os Ícones antes de chamar o walset
    set_icon_theme(new_mode)

    # 2. Atualiza o JSON (para que o walset leia o modo correto)
    state["mode"] = new_mode
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=4)

    # 3. Reaplica o tema usando o walset
    # O walset rodará os hooks (Waybar, SwayNC, etc)
    subprocess.run(["walset", img, scm, new_mode])

if __name__ == "__main__":
    main()
