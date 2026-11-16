#!/usr/bin/env python3
import os
import sys
import json
import shutil
import subprocess
import traceback
from datetime import datetime
from pathlib import Path
from typing import Optional

CACHE_DIR  = Path.home() / ".cache" / "wallset"
STATE_FILE = CACHE_DIR / "state.json"
SCHEMA, KEY = "org.gnome.desktop.interface", "color-scheme"


def log(msg: str, *, err: bool = False) -> None:
    stream = sys.stderr if err else sys.stdout
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}", file=stream, flush=True)


def _resolve(name: str, fallback: str) -> str:
    return shutil.which(name) or fallback


GSETTINGS = _resolve("gsettings",   "/usr/bin/gsettings")
NOTIFY    = _resolve("notify-send", "/usr/bin/notify-send")
WALLSET   = (
    shutil.which("wallset")
    or shutil.which("walset")
    or str(Path.home() / ".local" / "bin" / "wallset")
)


def run_checked(cmd: list, *, what: str) -> Optional[str]:
    """Roda cmd; em falha loga stdout/stderr e retorna None. Em sucesso, retorna stdout."""
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        log(f"[erro] {what}: binário não encontrado: {cmd[0]!r}", err=True)
        return None
    except subprocess.CalledProcessError as e:
        log(f"[erro] {what}: exit {e.returncode}", err=True)
        if e.stdout and e.stdout.strip():
            log(f"        stdout: {e.stdout.strip()}", err=True)
        if e.stderr and e.stderr.strip():
            log(f"        stderr: {e.stderr.strip()}", err=True)
        return None
    except OSError as e:
        log(f"[erro] {what}: {e}", err=True)
        return None
    return r.stdout


def read_state() -> Optional[dict]:
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except FileNotFoundError:
        log(f"[erro] state file não encontrado: {STATE_FILE}", err=True)
    except json.JSONDecodeError as e:
        log(f"[erro] state file inválido ({e}): {STATE_FILE}", err=True)
    except OSError as e:
        log(f"[erro] lendo {STATE_FILE}: {e}", err=True)
    return None


def current_mode() -> Optional[str]:
    out = run_checked([GSETTINGS, "get", SCHEMA, KEY], what="gsettings get color-scheme")
    if out is None:
        log("[dica] se o erro acima for de D-Bus, adicione ao unit: "
            "Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus", err=True)
        return None
    return "dark" if "prefer-dark" in out else "light"


def set_icon_theme(mode: str) -> bool:
    current_out = run_checked(
        [GSETTINGS, "get", SCHEMA, "icon-theme"], what="gsettings get icon-theme"
    )
    if current_out is None:
        return False
    current = current_out.strip().strip("'")

    base = current.removesuffix("-dark").removesuffix("-light")
    new_theme = f"{base}-{mode}"

    icon_dirs = [
        "/usr/share/icons",
        str(Path.home() / ".local" / "share" / "icons"),
        str(Path.home() / ".icons"),
    ]
    if any(os.path.isdir(os.path.join(d, new_theme)) for d in icon_dirs):
        if run_checked(
            [GSETTINGS, "set", SCHEMA, "icon-theme", new_theme],
            what=f"gsettings set icon-theme {new_theme}",
        ) is None:
            return False
        log(f"[gsettings] icon-theme → '{new_theme}'")
        return True

    msg = f"Variante '{new_theme}' não encontrada. Mantendo '{current}'."
    log(f"[aviso] {msg}")
    # notify-send é cosmético: não derruba o fluxo por causa dele
    try:
        r = subprocess.run(
            [NOTIFY, "-a", "wallset", "Tema de ícones", msg],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            log(f"[aviso] notify-send rc={r.returncode}: {r.stderr.strip()}", err=True)
    except FileNotFoundError:
        log(f"[aviso] notify-send não encontrado: {NOTIFY}", err=True)
    return True


def apply(mode: str) -> bool:
    state = read_state()
    if state is None:
        return False
    if state.get("mode") == mode:
        log(f"[daemon] modo já é '{mode}', nada a fazer")
        return True

    log(f"[daemon] aplicando modo → {mode}")

    if not set_icon_theme(mode):
        log("[erro] icon-theme falhou; state NÃO atualizado", err=True)
        return False

    wallpaper = state.get("wallpaper")
    if not wallpaper:
        log("[erro] state.wallpaper ausente; rode 'wallset' manualmente primeiro", err=True)
        return False
    scheme = state.get("scheme", "content")

    if run_checked([WALLSET, wallpaper, scheme, mode], what=f"wallset {mode}") is None:
        log("[erro] wallset falhou; state NÃO atualizado", err=True)
        return False

    state["mode"] = mode
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=4)
    except OSError as e:
        log(f"[erro] escrevendo {STATE_FILE}: {e}", err=True)
        return False

    log(f"[daemon] modo '{mode}' aplicado e salvo")
    return True


def main() -> int:
    log(f"[daemon] iniciando — gsettings={GSETTINGS}  wallset={WALLSET}  notify={NOTIFY}")

    if not STATE_FILE.exists():
        log(f"[erro] {STATE_FILE} não existe. Rode o wallset uma vez antes.", err=True)
        return 0  # nada a fazer; evita restart-loop

    mode = current_mode()
    if mode is None:
        return 1  # transitório: deixa o systemd retentar

    apply(mode)

    log(f"[daemon] monitorando {SCHEMA} {KEY}")
    try:
        proc = subprocess.Popen(
            [GSETTINGS, "monitor", SCHEMA, KEY],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, bufsize=1,
        )
    except (FileNotFoundError, OSError) as e:
        log(f"[erro] iniciando gsettings monitor: {e}", err=True)
        return 1

    exit_code = 0
    try:
        for line in proc.stdout:
            line = line.rstrip("\n")
            log(f"[monitor] {line}")
            new_mode = "dark" if "prefer-dark" in line else "light"
            apply(new_mode)
    except Exception as e:
        log(f"[erro] leitura do monitor: {e}", err=True)
        exit_code = 1
    finally:
        try:
            proc.terminate()
            rc = proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            rc = proc.wait()

        err = ""
        try:
            err = proc.stderr.read() if proc.stderr else ""
        except Exception:
            pass

        if rc != 0 and rc != -15:  # -15 = SIGTERM nosso, ok
            log(f"[erro] gsettings monitor terminou (rc={rc}). stderr: {err.strip()}", err=True)
            exit_code = 1
        elif rc == 0:
            log("[daemon] gsettings monitor terminou normalmente; encerrando")

    return exit_code


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        log("[daemon] interrompido (Ctrl+C / SIGTERM)")
        sys.exit(0)
    except Exception:
        log("[erro] exceção não tratada:\n" + traceback.format_exc(), err=True)
        sys.exit(1)
