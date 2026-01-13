#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

STATE_FILE = Path.home() / ".cache/waybar-clock-mode"
STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

mode = STATE_FILE.read_text().strip() if STATE_FILE.exists() else "time"
action = sys.argv[1] if len(sys.argv) > 1 else ""

if action == "toggle":
    mode = "date" if mode == "time" else "time"
    STATE_FILE.write_text(mode)

elif action == "open":
    if mode == "time":
        subprocess.Popen(["gnome-clocks"])
    else:
        subprocess.Popen(["gnome-calendar"])