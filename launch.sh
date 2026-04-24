#!/usr/bin/env bash
# LinuxDPI-TR – Başlatıcı
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "$WAYLAND_DISPLAY" ]; then
    export WAYLAND_DISPLAY
elif [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi
exec python3 "$SCRIPT_DIR/linuxdpi.py"
