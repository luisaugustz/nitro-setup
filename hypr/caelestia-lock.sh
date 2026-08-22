#!/usr/bin/env bash
# Lock via Caelestia: garante o shell no ar e dispara o lock nativo (global).
# Usado pelo hypridle-caelestia.conf como lock_cmd.
pgrep -f 'qs.*caelestia|caelestia.*shell' >/dev/null 2>&1 || caelestia shell -d
sleep 0.2
hyprctl dispatch global caelestia:lock
