#!/usr/bin/env bash
# Trava a tela com hyprlock. Ao DESTRAVAR, verifica se a barra (nwg-panel)
# reapareceu — as vezes o layer-shell dela nao remapeia depois do ciclo de
# lock/DPMS. Se sumiu, reinicia so a barra (sem flicker quando esta ok).

# Nao empilhar um segundo locker (hyprlock ja e idempotente, mas evita rodar o
# heal indevidamente se lock.sh for chamado de novo enquanto ja travado).
if pidof -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

hyprlock   # bloqueia ate o usuario destravar

# --- pos-unlock: cura a barra se o layer dela sumiu ---
sleep 0.5
if ! hyprctl layers 2>/dev/null | grep -q "namespace: nwg-panel"; then
    pkill -x nwg-panel 2>/dev/null
    sleep 0.3
    setsid nwg-panel -c hyprland-1 -s hyprland-1.css >/dev/null 2>&1 </dev/null &
fi
