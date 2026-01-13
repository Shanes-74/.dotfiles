#!/usr/bin/env python3
import subprocess
import os
import json

# Caminho do seu tema
ROFI_THEME = os.path.expanduser("~/.dotfiles/config/.config/scripts/window_tab/wintab.rasi")

def run():
    try:
        # Pega a lista de janelas em JSON
        result = subprocess.run(["hyprctl", "-j", "clients"], capture_output=True, text=True)
        clients = json.loads(result.stdout)
        
        menu_entries = []
        window_map = {}

        for client in clients:
            # Filtra janelas inválidas
            if not client['title'] or client['workspace']['id'] < 0:
                continue

            full_title = client['title']
            app_class = client['class']
            addr = client['address']

            # Limite de 25 caracteres para o nome da janela
            display_title = (full_title[:22] + '...') if len(full_title) > 25 else full_title
            
            # Formato: Texto visível \0 Ícone nos metadados
            entry = f"{display_title}\0icon\x1f{app_class}"
            
            menu_entries.append(entry)
            window_map[display_title] = addr
            
        if not menu_entries:
            return

        # DYNAMICS: Ajusta as colunas conforme o número de janelas (máximo 10)
        num_windows = len(menu_entries)
        cols = min(num_windows, 10)

        rofi_cmd = [
            "rofi", "-dmenu", "-i", "-no-config",
            "-theme", ROFI_THEME,
            "-p", "Janelas",
            "-show-icons",
            "-columns", str(cols) # Isso impede que as janelas fiquem "espremidas"
        ]

        proc = subprocess.run(rofi_cmd, input="\n".join(menu_entries), capture_output=True, text=True)
        selected = proc.stdout.strip()

        if selected in window_map:
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{window_map[selected]}"])

    except Exception as e:
        print(f"Erro: {e}")

if __name__ == "__main__":
    run()