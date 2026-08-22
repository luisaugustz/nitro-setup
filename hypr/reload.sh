#!/usr/bin/env bash
# Recarrega o Hyprland E religa o hypridle (que as vezes fica "surdo" apos reload,
# fazendo a tela nunca apagar). pkill -x usa nome exato (nao pega este script).
# Detecta o shell ativo (shell-active.conf) para religar o hypridle com a config
# certa: caelestia (lock nativo) ou nwg (hyprlock via lock.sh).
hyprctl reload
pkill -x hypridle
sleep 1
if readlink ~/.config/hypr/shell-active.conf 2>/dev/null | grep -q caelestia; then
    setsid hypridle -c ~/.config/hypr/hypridle-caelestia.conf >/dev/null 2>&1 < /dev/null &
else
    setsid hypridle >/dev/null 2>&1 < /dev/null &
fi
