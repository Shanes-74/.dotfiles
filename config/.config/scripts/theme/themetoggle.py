#!/usr/bin/env python3
import os
import re
import json
import subprocess
import configparser
from pathlib import Path

# --- CONFIGURAÇÕES ---
CACHE_DIR = os.path.join(Path.home(), ".cache", "walset")
STATE_FILE = os.path.join(CACHE_DIR, "state.json")

ICON_DIRS = [
    Path.home() / ".local/share/icons",
    Path("/usr/share/icons"),
]

QT_CONFIGS = [
    Path.home() / ".config/qt5ct/qt5ct.conf",
    Path.home() / ".config/qt6ct/qt6ct.conf",
]

# ------------------------------------------------------------------ #
#  Helpers                                                             #
# ------------------------------------------------------------------ #

def get_current_icon_theme() -> str:
    """Lê o tema de ícones atual via gsettings."""
    result = subprocess.run(
        ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
        capture_output=True, text=True, check=False
    )
    return result.stdout.strip().strip("'")

def get_base_name(theme_name: str) -> str:
    """Remove sufixo -dark/-light/-Dark/-Light do nome do tema."""
    return re.sub(r"[-_](dark|light)$", "", theme_name, flags=re.IGNORECASE)

def find_icon_theme(base_name: str, mode: str) -> str | None:
    """
    Procura nos diretórios de ícones um tema cujo nome seja
    {base_name}-{mode} ou {base_name}-{Mode}.
    Retorna o nome exato do diretório encontrado, ou None.
    """
    candidates = {f"{base_name}-{mode}", f"{base_name}-{mode.capitalize()}"}

    for icon_dir in ICON_DIRS:
        if not icon_dir.exists():
            continue
        for entry in icon_dir.iterdir():
            if entry.is_dir() and entry.name in candidates:
                return entry.name

    return None

# ------------------------------------------------------------------ #
#  Aplicadores                                                         #
# ------------------------------------------------------------------ #

def set_gsettings_icon_theme(theme: str, old_theme: str):
    """Aplica o tema via gsettings (GTK / GNOME)."""
    try:
        subprocess.run(
            ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", theme],
            check=False
        )
        print(f"[gsettings]  '{old_theme}' → '{theme}'")
    except Exception as e:
        print(f"[gsettings]  Erro: {e}")

def set_qt_icon_theme(theme: str, config_path: Path):
    """
    Aplica o tema no arquivo de configuração do qt5ct / qt6ct.
    Cria o arquivo/seção se não existir.
    """
    if not config_path.exists():
        print(f"[{config_path.name}]  Arquivo não encontrado, ignorando.")
        return

    # configparser por padrão converte chaves para lowercase;
    # optionxform=str preserva a capitalização original.
    cfg = configparser.ConfigParser()
    cfg.optionxform = str
    cfg.read(config_path)

    section = "Appearance"
    if not cfg.has_section(section):
        cfg.add_section(section)

    old = cfg.get(section, "icon_theme", fallback="(não definido)")
    cfg.set(section, "icon_theme", theme)

    with open(config_path, "w") as f:
        cfg.write(f)

    print(f"[{config_path.name}]  '{old}' → '{theme}'")

def set_icon_theme(mode: str, current_theme: str):
    """Resolve o tema alvo e aplica em todos os backends."""
    base  = get_base_name(current_theme)
    theme = find_icon_theme(base, mode)

    if theme is None:
        print(f"Aviso: nenhum tema encontrado para '{base}' no modo '{mode}'. "
              f"Mantendo '{current_theme}'.")
        return

    set_gsettings_icon_theme(theme, current_theme)

    for conf in QT_CONFIGS:
        set_qt_icon_theme(theme, conf)

# ------------------------------------------------------------------ #
#  Main                                                                #
# ------------------------------------------------------------------ #

def main():
    if not os.path.exists(STATE_FILE):
        print("Erro: Execute o walset primeiro para gerar o cache.")
        return

    with open(STATE_FILE, "r") as f:
        state = json.load(f)

    img      = state.get("wallpaper")
    scm      = state.get("scheme", "content")
    old_mode = state.get("mode", "dark")
    new_mode = "light" if old_mode == "dark" else "dark"

    # 1. Lê tema atual e aplica o novo em todos os backends
    current_theme = get_current_icon_theme()
    set_icon_theme(new_mode, current_theme)

    # 2. Atualiza o JSON com o novo modo
    state["mode"] = new_mode
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=4)

    # 3. Reaplica o tema completo via walset
    subprocess.run(["walset", img, scm, new_mode])

if __name__ == "__main__":
    main()