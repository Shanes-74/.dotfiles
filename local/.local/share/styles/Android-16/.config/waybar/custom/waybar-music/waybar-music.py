#!/usr/bin/env python3
"""
waybar-music.py - Letreiro + capa giratória (polling)
Requer: playerctl, Pillow >= 9.1, matugen
"""

import argparse
import json
import os
import signal
import subprocess
import sys
import time
import threading
import shutil
import urllib.request
from pathlib import Path
from typing import Optional, List

try:
    from PIL import Image, ImageDraw, ImageOps, ImageFilter
except ImportError:
    sys.exit("ERRO: Instale Pillow: pip install Pillow")

# ----------------------------------------------------------------------
# Configurações
# ----------------------------------------------------------------------
POLL_INTERVAL = 0.5            # intervalo (s) do loop principal (status/música)
ICON_POLL_INTERVAL = 0.5       # intervalo (s) de atualização dos ícones
ACTIVE_PLAYER_CACHE_TTL = 0.5  # cache (s) do player ativo

SCROLL_SPEED = 3              # velocidade do letreiro (caracteres por segundo)
SCROLL_LENGTH = 20             # nº máximo de caracteres visíveis no letreiro
SCROLL_FPS = 60                # frequência de atualização do scroll (quadros/segundo)

IMAGE_SIZE = 256               # tamanho total da imagem (px)
DISK_MARGIN = 12                # margem uniforme entre o CD e as bordas da imagem (reduzida ainda mais)
HOLE_RADIUS = 32               # raio do furo central (px)
BORDER_COLOR = (128, 128, 128, 255)
BORDER_WIDTH = 6               # espessura da borda (px) – igual para externa e interna

ROTATION_STEP = 2             # graus por frame da rotação
ROTATION_FPS = 60              # frames por segundo da rotação

# Sombra uniforme ao redor do disco
SHADOW_COLOR = (0, 0, 0, 150)  # cor da sombra (RGBA)
SHADOW_BLUR = 10               # intensidade do desfoque (px)

# ----------------------------------------------------------------------
# Cache e arquivos por instância
# ----------------------------------------------------------------------
CACHE_DIR = Path.home() / ".cache" / "waybar-music"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

ACTIVE_PLAYER_FILE = CACHE_DIR / "active_player"
CURRENT_STATUS_FILE = CACHE_DIR / "current_status"
PID = os.getpid()
LAST_URL_FILE = CACHE_DIR / f"last_url_{PID}.txt"
LAST_MUSIC_FILE = CACHE_DIR / f"last_music_{PID}.txt"
STATUS_FILE = CACHE_DIR / f"status_{PID}.txt"

COVER_FILE = Path("/tmp/cd.png")                     # imagem exibida (rotacionada)
BASE_COVER_FILE = CACHE_DIR / "cover_base.png"       # imagem base sem rotação (tratada)
ORIGINAL_COVER_FILE = CACHE_DIR / "cover.png"        # cover original no cache
TMP_ORIGINAL_COVER_FILE = Path("/tmp/cover.png")     # cópia do original em /tmp

CSS_DIR = Path.home() / ".config" / "waybar" / "custom" / "waybar-music"
CSS_FILE = CSS_DIR / "cover.css"
MATUGEN_CONFIG = CSS_DIR / "config.toml"

# ----------------------------------------------------------------------
# Helpers do playerctl (com cache do player ativo)
# ----------------------------------------------------------------------
_active_player_cache = None
_cache_time = 0.0

def _get_active_player_real() -> Optional[str]:
    try:
        out = subprocess.check_output(["playerctl", "-l"], text=True).strip()
        players = out.splitlines() if out else []
    except subprocess.CalledProcessError:
        return None
    if not players:
        return None

    stored = ACTIVE_PLAYER_FILE.read_text().strip() if ACTIVE_PLAYER_FILE.exists() else None
    if stored and stored in players:
        return stored

    for p in players:
        try:
            status = subprocess.check_output(
                ["playerctl", "-p", p, "status"], text=True, stderr=subprocess.DEVNULL
            ).strip()
            if status == "Playing":
                return p
        except subprocess.CalledProcessError:
            continue
    return players[0]

def get_active_player() -> Optional[str]:
    global _active_player_cache, _cache_time
    now = time.monotonic()
    if _active_player_cache is not None and (now - _cache_time) < ACTIVE_PLAYER_CACHE_TTL:
        return _active_player_cache
    _active_player_cache = _get_active_player_real()
    _cache_time = now
    return _active_player_cache

def playerctl_command(args: List[str]) -> subprocess.CompletedProcess:
    player = get_active_player()
    cmd = ["playerctl"]
    if player:
        cmd += ["-p", player]
    cmd += args
    return subprocess.run(cmd, capture_output=True, text=True)

def get_status() -> str:
    try:
        res = playerctl_command(["status"])
        return res.stdout.strip() if res.returncode == 0 else "Stopped"
    except Exception:
        return "Stopped"

def get_metadata(fmt: str = "{{ title }} - {{ artist }}") -> str:
    try:
        res = playerctl_command(["metadata", "--format", fmt])
        return res.stdout.strip() if res.returncode == 0 else ""
    except Exception:
        return ""

def get_title() -> str:
    return get_metadata("{{ title }}") or "Nada tocando"

def get_art_url() -> Optional[str]:
    try:
        res = playerctl_command(["metadata", "mpris:artUrl"])
        return res.stdout.strip() if res.returncode == 0 else None
    except Exception:
        return None

# ----------------------------------------------------------------------
# Modos especiais
# ----------------------------------------------------------------------
def open_player():
    player = get_active_player()
    if not player:
        return
    base = player.split('.')[0]
    launch_map = {"spotify": "spotify", "firefox": "firefox", "chromium": "chromium"}
    cmd = launch_map.get(base, base)

    def find_addr():
        # ... (implementação original mantida)
        return None  # substitua pelo código real se necessário

    addr = find_addr()
    if not addr:
        subprocess.Popen(cmd, start_new_session=True)
        for _ in range(30):
            time.sleep(0.2)
            addr = find_addr()
            if addr:
                break
    if addr:
        subprocess.run(["hyprctl", "dispatch", f"hl.dsp.focus({{ window = 'address:{addr}' }})"])
    sys.exit(0)

def switch_player(direction: int):
    try:
        players = subprocess.check_output(["playerctl", "-l"], text=True).strip().splitlines()
    except Exception:
        players = []
    if not players:
        sys.exit(0)
    current = get_active_player()
    idx = players.index(current) if current in players else 0
    new_idx = (idx + direction) % len(players)
    ACTIVE_PLAYER_FILE.write_text(players[new_idx])
    sys.exit(0)

def pc_mode(args):
    res = playerctl_command(args)
    sys.exit(res.returncode)

# ----------------------------------------------------------------------
# Ícones
# ----------------------------------------------------------------------
def icon_stream(mode: str):
    last_status = None
    while True:
        try:
            status = CURRENT_STATUS_FILE.read_text().strip()
        except Exception:
            status = "Stopped"
        if status != last_status:
            cls = status.lower() if status else "stopped"
            icon = {"Playing": "", "Paused": ""}.get(status, "") if mode == "playpause" else mode
            print(json.dumps({"text": icon, "class": cls}), flush=True)
            last_status = status
        time.sleep(ICON_POLL_INTERVAL)

# ----------------------------------------------------------------------
# Processamento de imagem com sombra uniforme e margens
# ----------------------------------------------------------------------
def draw_borders(draw, bbox):
    """Desenha bordas externa e interna com a mesma espessura."""
    # Borda externa (na borda do disco)
    draw.ellipse(bbox, outline=BORDER_COLOR, width=BORDER_WIDTH)
    # Borda do furo central (contorno circular)
    r = HOLE_RADIUS
    cx, cy = (bbox[0] + bbox[2]) // 2, (bbox[1] + bbox[3]) // 2
    draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        outline=BORDER_COLOR,
        width=BORDER_WIDTH
    )

def add_uniform_shadow(image: Image.Image, bbox):
    """Adiciona sombra uniforme ao redor do disco (sem deslocamento)."""
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)

    # Desenha um círculo com a cor definida em SHADOW_COLOR
    draw.ellipse(bbox, fill=SHADOW_COLOR)
    shadow = shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))

    composited = Image.alpha_composite(shadow, image)
    return composited

def generate_default_cover(path: Path):
    img = Image.new("RGBA", (IMAGE_SIZE, IMAGE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Coordenadas do disco com margem
    bbox = [DISK_MARGIN, DISK_MARGIN, IMAGE_SIZE - DISK_MARGIN, IMAGE_SIZE - DISK_MARGIN]
    # Desenha o disco cinza
    draw.ellipse(bbox, fill=(166, 166, 166, 255))
    # Furo central transparente
    r = HOLE_RADIUS
    cx, cy = (bbox[0] + bbox[2]) // 2, (bbox[1] + bbox[3]) // 2
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(0, 0, 0, 0))
    # Bordas
    draw_borders(draw, bbox)
    # Sombra
    img = add_uniform_shadow(img, bbox)
    img.save(path)

def process_cover(input_path: Path, output_path: Path) -> bool:
    """Redimensiona, aplica máscara circular, furo central, bordas e sombra."""
    try:
        # Abre a imagem original e redimensiona para o tamanho do disco
        cover = Image.open(input_path).convert("RGBA")
        disk_size = IMAGE_SIZE - 2 * DISK_MARGIN
        cover = ImageOps.fit(cover, (disk_size, disk_size), centering=(0.5, 0.5))

        # Cria uma imagem transparente do tamanho total
        img = Image.new("RGBA", (IMAGE_SIZE, IMAGE_SIZE), (0, 0, 0, 0))
        bbox = [DISK_MARGIN, DISK_MARGIN, IMAGE_SIZE - DISK_MARGIN, IMAGE_SIZE - DISK_MARGIN]

        # Aplica máscara circular no cover
        mask = Image.new("L", (disk_size, disk_size), 0)
        draw_mask = ImageDraw.Draw(mask)
        draw_mask.ellipse([0, 0, disk_size - 1, disk_size - 1], fill=255)
        cover.putalpha(mask)

        # Cola o cover na posição correta (com margem)
        img.paste(cover, (DISK_MARGIN, DISK_MARGIN), cover)

        draw = ImageDraw.Draw(img)
        # Furo central
        r = HOLE_RADIUS
        cx, cy = (bbox[0] + bbox[2]) // 2, (bbox[1] + bbox[3]) // 2
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(0, 0, 0, 0))
        # Bordas
        draw_borders(draw, bbox)
        # Sombra
        img = add_uniform_shadow(img, bbox)
        img.save(output_path)
        return True
    except Exception:
        return False

def ensure_base_image():
    if not BASE_COVER_FILE.exists():
        generate_default_cover(BASE_COVER_FILE)

def generate_css_colors():
    if not ORIGINAL_COVER_FILE.exists() or not MATUGEN_CONFIG.exists():
        return
    CSS_DIR.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(
            ["matugen", "image", str(ORIGINAL_COVER_FILE),
             "-t", "scheme-content", "--source-color-index", "0",
             "-c", str(MATUGEN_CONFIG)],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

def download_cover():
    url = get_art_url()
    if not url:
        ensure_base_image()
        shutil.copy(BASE_COVER_FILE, ORIGINAL_COVER_FILE)
        shutil.copy(BASE_COVER_FILE, COVER_FILE)
        shutil.copy(BASE_COVER_FILE, TMP_ORIGINAL_COVER_FILE)
        return

    tmp = Path(f"/tmp/waybar_cover_temp_{PID}.png")
    if url.startswith("file://"):
        shutil.copy(url[7:], tmp)
    else:
        try:
            urllib.request.urlretrieve(url, tmp)
        except Exception:
            pass

    if tmp.exists() and tmp.stat().st_size > 0:
        shutil.copy(tmp, ORIGINAL_COVER_FILE)
        shutil.copy(tmp, TMP_ORIGINAL_COVER_FILE)

        if process_cover(tmp, BASE_COVER_FILE):
            shutil.copy(BASE_COVER_FILE, COVER_FILE)
            LAST_URL_FILE.write_text(url)
            generate_css_colors()
        else:
            ensure_base_image()
            shutil.copy(BASE_COVER_FILE, COVER_FILE)
        tmp.unlink(missing_ok=True)
    else:
        ensure_base_image()
        shutil.copy(BASE_COVER_FILE, COVER_FILE)
        shutil.copy(BASE_COVER_FILE, TMP_ORIGINAL_COVER_FILE)

# ----------------------------------------------------------------------
# Rotação (thread) - agora com escrita atômica
# ----------------------------------------------------------------------
class RotationThread(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True)
        self._stop_event = threading.Event()
        self._rotating = threading.Event()
        self.angle = 0
        self._needs_restore = False
        self._base_image = None
        self._lock = threading.Lock()

    def _atomic_save(self, image: Image.Image, path: Path):
        """Salva a imagem atomicamente para evitar leitura parcial pelo Waybar."""
        tmp = path.with_suffix(".tmp.png")
        image.save(tmp)
        os.replace(tmp, path)

    def _load_base_image(self):
        if BASE_COVER_FILE.exists():
            try:
                self._base_image = Image.open(BASE_COVER_FILE).convert("RGBA")
            except Exception:
                self._base_image = None
        else:
            self._base_image = None

    def run(self):
        while not self._stop_event.is_set():
            if self._rotating.is_set():
                if self._base_image is None:
                    self._load_base_image()
                if self._base_image:
                    with self._lock:
                        try:
                            rotated = self._base_image.rotate(self.angle, expand=False)
                            self._atomic_save(rotated, COVER_FILE)
                            self.angle = (self.angle - ROTATION_STEP) % 360
                        except Exception:
                            pass
                self._needs_restore = True
            elif self._needs_restore:
                self._load_base_image()
                if self._base_image:
                    try:
                        self._atomic_save(self._base_image, COVER_FILE)
                    except Exception:
                        pass
                self._needs_restore = False
            time.sleep(1.0 / ROTATION_FPS)

    def start_rotation(self):
        self._rotating.set()

    def stop_rotation(self):
        self._rotating.clear()
        self._needs_restore = True

    def update_base_image(self):
        self._load_base_image()

    def stop(self):
        self._stop_event.set()

# ----------------------------------------------------------------------
# Scrolling (thread dedicada para suavidade)
# ----------------------------------------------------------------------
class ScrollText:
    def __init__(self, length=SCROLL_LENGTH):
        self.length = length
        self._last_text = ""
        self._offset = 0.0
        self._scrolling = False
        self.lock = threading.Lock()
        self.SPACER = "   "
        self._last_step_time = None
        self._stop_event = threading.Event()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def _run(self):
        while not self._stop_event.is_set():
            if self._scrolling:
                self.step()
            time.sleep(1.0 / SCROLL_FPS)

    def update_text(self, text: str):
        with self.lock:
            if text != self._last_text:
                self._last_text = text
                self._offset = 0.0
                self._last_step_time = None

    def set_scrolling(self, active: bool):
        self._scrolling = active

    def get_current_display(self) -> str:
        with self.lock:
            if not self._scrolling or len(self._last_text) <= self.length:
                return self._last_text[:self.length]
            full = self._last_text + self.SPACER
            double = full * 2
            start = int(self._offset) % len(full)
            return double[start:start + self.length]

    def step(self):
        with self.lock:
            if not self._scrolling or len(self._last_text) <= self.length:
                return
            now = time.monotonic()
            if self._last_step_time is None:
                self._last_step_time = now
                return
            delta = now - self._last_step_time
            self._last_step_time = now
            self._offset += SCROLL_SPEED * delta

    def stop(self):
        self._stop_event.set()

# ----------------------------------------------------------------------
# Loop principal
# ----------------------------------------------------------------------
def main_loop():
    def sigterm_handler(signum, frame):
        raise KeyboardInterrupt()
    signal.signal(signal.SIGTERM, sigterm_handler)
    signal.signal(signal.SIGQUIT, sigterm_handler)

    ensure_base_image()
    shutil.copy(BASE_COVER_FILE, COVER_FILE)
    download_cover()

    init_status = get_status()
    init_full = get_metadata() or "Nada tocando"
    STATUS_FILE.write_text(init_status)
    CURRENT_STATUS_FILE.write_text(init_status)

    rot_thread = RotationThread()
    rot_thread.start()
    if init_status == "Playing":
        rot_thread.update_base_image()
        rot_thread.start_rotation()

    scroller = ScrollText()
    scroller.update_text(init_full)
    scroller.set_scrolling(init_status == "Playing")

    last_status = init_status
    last_music = init_full

    def emit_json():
        try:
            status = STATUS_FILE.read_text().strip()
        except Exception:
            status = "Stopped"
        if status == "Playing":
            display = scroller.get_current_display()
            tooltip = last_music
            player = get_active_player()
            if player:
                tooltip += f" - {player.split('.')[0].capitalize()}"
            print(json.dumps({
                "text": display,
                "class": "playing",
                "tooltip": tooltip
            }), flush=True)
        elif status == "Paused":
            short = last_music[:16] + ("..." if len(last_music) > 16 else "")
            tooltip = last_music
            player = get_active_player()
            if player:
                tooltip += f" - {player.split('.')[0].capitalize()}"
            print(json.dumps({
                "text": short,
                "class": "paused",
                "tooltip": tooltip
            }), flush=True)
        else:
            print(json.dumps({
                "text": "",
                "class": "stopped",
                "tooltip": "Nada tocando"
            }), flush=True)

    emit_json()

    try:
        while True:
            time.sleep(POLL_INTERVAL)
            status = get_status()
            music = get_metadata() or "Nada tocando"

            STATUS_FILE.write_text(status)
            CURRENT_STATUS_FILE.write_text(status)

            if music != last_music:
                download_cover()
                rot_thread.update_base_image()
                last_music = music
                scroller.update_text(music)

            if status == "Playing":
                if not rot_thread._rotating.is_set():
                    rot_thread.start_rotation()
                scroller.set_scrolling(True)
            else:
                if rot_thread._rotating.is_set():
                    rot_thread.stop_rotation()
                scroller.set_scrolling(False)
                if status == "Stopped":
                    for f in [COVER_FILE, BASE_COVER_FILE, TMP_ORIGINAL_COVER_FILE]:
                        try:
                            f.unlink(missing_ok=True)
                        except Exception:
                            pass
                    CSS_FILE.write_text("")

            if status != last_status or status == "Playing":
                emit_json()

            last_status = status
    except KeyboardInterrupt:
        pass
    finally:
        rot_thread.stop()
        scroller.stop()
        cleanup()

def cleanup():
    for f in [COVER_FILE, BASE_COVER_FILE, TMP_ORIGINAL_COVER_FILE,
              LAST_URL_FILE, LAST_MUSIC_FILE, STATUS_FILE]:
        try:
            f.unlink(missing_ok=True)
        except Exception:
            pass
    CSS_FILE.write_text("")

# ----------------------------------------------------------------------
# Entrada
# ----------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-open", action="store_true")
    parser.add_argument("-next", action="store_true")
    parser.add_argument("-prev", action="store_true")
    parser.add_argument("-pc", nargs="*")
    parser.add_argument("-icon-playpause", action="store_true")
    parser.add_argument("-icon-prev", action="store_true")
    parser.add_argument("-icon-next", action="store_true")
    parser.add_argument("-icon-swipe", action="store_true")     # <-- nova flag
    args = parser.parse_args()

    if args.open:
        open_player()
    elif args.next:
        switch_player(1)
    elif args.prev:
        switch_player(-1)
    elif args.pc is not None:
        pc_mode(args.pc)
    elif args.icon_playpause:
        icon_stream("playpause")
    elif args.icon_prev:
        icon_stream("")
    elif args.icon_next:
        icon_stream("")
    elif args.icon_swipe:                                       # <-- novo branch
        icon_stream("")
    else:
        main_loop()
