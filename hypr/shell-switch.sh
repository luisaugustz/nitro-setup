#!/usr/bin/env bash
# shell-switch.sh — troca entre os shells caelestia <-> nwg.
# Aponta o symlink shell-active.conf, mata o shell atual, recarrega o Hyprland
# e sobe o autostart do shell escolhido.
#
#   ~/.config/hypr/shell-switch.sh caelestia
#   ~/.config/hypr/shell-switch.sh nwg
#
set -euo pipefail
HYPR="$HOME/.config/hypr"
target="${1:-}"

case "$target" in
  caelestia|nwg) ;;
  *) echo "uso: shell-switch.sh {caelestia|nwg}"; exit 1 ;;
esac

# 1) Mata o que estiver rodando dos dois lados (idempotente).
pkill -f 'qs.*caelestia' 2>/dev/null || true
caelestia shell -k 2>/dev/null || true
pkill -x nwg-panel 2>/dev/null || true
pkill -x nwg-dock-hyprland 2>/dev/null || true
pkill -x nwg-drawer 2>/dev/null || true
pkill -x nwg-screenshot-applet 2>/dev/null || true
pkill -x swaync 2>/dev/null || true
pkill -x hypridle 2>/dev/null || true

# 2) Aponta o symlink.
ln -sf "shell-$target.conf" "$HYPR/shell-active.conf"
echo "shell-active.conf -> shell-$target.conf"

# 3) Recarrega o Hyprland (aplica binds/source novos).
hyprctl reload >/dev/null 2>&1 || true
sleep 0.3

# 4) Sobe o autostart do shell escolhido (reload não re-executa exec-once).
if [ "$target" = "caelestia" ]; then
  caelestia shell -d
  setsid hypridle -c "$HYPR/hypridle-caelestia.conf" >/dev/null 2>&1 </dev/null &
else
  setsid swaync -c "$HOME/.config/swaync/hyprland.json" -s "$HOME/.config/swaync/hyprland-1.css" >/dev/null 2>&1 </dev/null &
  setsid nwg-drawer -r -c 6 -is 64 -fscol 2 -g Material-Black-Mango-BE -i Material-Black-Mango-BE -s hyprland-1.css -term kitty -ft -wm hyprland -pblock 'hyprlock' -pbsize 48 >/dev/null 2>&1 </dev/null &
  setsid nwg-panel -c hyprland-1 -s hyprland-1.css >/dev/null 2>&1 </dev/null &
  setsid nwg-dock-hyprland -d -p bottom -l overlay -a center -i 48 -hd 20 -s hyprland-1.css >/dev/null 2>&1 </dev/null &
  setsid hypridle >/dev/null 2>&1 </dev/null &
fi
echo "shell '$target' no ar."
