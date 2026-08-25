#!/usr/bin/env bash
# =============================================================================
# setup.sh — Nitro (RTX 4050 + Ryzen): Hyprland + Caelestia, espelhando o Luis.
# Rode DEPOIS de instalar o CachyOS (desktop Hyprland), como USUÁRIO NORMAL (sem sudo).
# O CachyOS já traz: kernel linux-cachyos, driver NVIDIA, SDDM, multilib e zram.
# Este script troca a config do CachyOS pela do Luis e instala o resto do rig.
# Uso:
#   git clone https://github.com/luisaugustz/nitro-setup.git
#   cd nitro-setup && ./setup.sh
# =============================================================================
set -euo pipefail

# diretório do repo (pra achar a pasta ./hypr)
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">> [1/6] yay (helper do AUR)"
# o CachyOS já vem com o paru; se preferir, é só trocar 'yay' por 'paru' abaixo.
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm git base-devel
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  ( cd "$tmp/yay" && makepkg -si --noconfirm )
fi

echo ">> [2/6] pacotes (repo + AUR)"
# multilib já vem habilitado no CachyOS, então os lib32-* funcionam direto.
# headers do kernel: no CachyOS é linux-cachyos-headers (NÃO linux-headers),
# senão o driver NVIDIA (DKMS) não compila pro kernel em uso.
yay -S --needed --noconfirm --answerdiff=None --answerclean=None \
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  qt5-wayland qt6-wayland polkit-kde-agent foot firefox thunar gvfs \
  grim slurp wl-clipboard cliphist wtype brightnessctl playerctl pavucontrol \
  networkmanager network-manager-applet bluez bluez-utils blueman \
  power-profiles-daemon zram-generator sddm sddm-conf \
  noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono-nerd \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber gst-plugin-pipewire \
  linux-cachyos-headers amd-ucode nvidia-utils lib32-nvidia-utils nvidia-prime egl-wayland \
  mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader vulkan-radeon lib32-vulkan-radeon \
  steam discord vencord-installer-bin onlyoffice-bin \
  qemu-full libvirt virt-manager edk2-ovmf dnsmasq swtpm dmidecode \
  caelestia-shell caelestia-cli hyprmod

# driver NVIDIA: o CachyOS geralmente já instalou um -dkms na detecção de hardware.
# Só instala o nvidia-open-dkms se NENHUM driver dkms estiver presente (evita conflito
# entre nvidia-dkms e nvidia-open-dkms).
if ! pacman -Qq 2>/dev/null | grep -qE '^nvidia(-open)?-dkms$'; then
  yay -S --needed --noconfirm nvidia-open-dkms
fi

echo ">> [3/6] NVIDIA: modeset + módulos no initramfs"
echo 'options nvidia_drm modeset=1' | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
# só mexe no mkinitcpio se for esse o gerador de initramfs (padrão do CachyOS)
if [ -f /etc/mkinitcpio.conf ]; then
  if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
  fi
  sudo mkinitcpio -P
fi

echo ">> [4/6] copiar a config do hypr (substitui a do CachyOS)"
mkdir -p "$HOME/.config"
# guarda a config que veio do CachyOS antes de trocar pela do Luis
if [ -d "$HOME/.config/hypr" ] && [ ! -d "$HOME/.config/hypr.cachyos.bak" ]; then
  mv "$HOME/.config/hypr" "$HOME/.config/hypr.cachyos.bak"
fi
cp -r "$REPO/hypr" "$HOME/.config/hypr"
# corrige caminhos absolutos do Luis -> home do amigo
grep -rl '/home/luis' "$HOME/.config/hypr" 2>/dev/null | xargs -r sed -i "s#/home/luis#$HOME#g"

echo ">> [5/6] env do NVIDIA pro Hyprland"
cat > "$HOME/.config/hypr/nvidia.conf" <<'EOF'
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct

cursor {
    no_hardware_cursors = true
}
EOF
grep -q 'nvidia.conf' "$HOME/.config/hypr/hyprland.conf" \
  || echo 'source = ~/.config/hypr/nvidia.conf' >> "$HOME/.config/hypr/hyprland.conf"

echo ">> [6/6] serviços"
# no CachyOS a maioria já está ligada; 'enable' de novo não dá problema.
sudo systemctl enable NetworkManager bluetooth sddm libvirtd
sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume
sudo usermod -aG libvirt "$USER"

echo
echo "============================================================"
echo " Tudo pronto!"
echo " Falta 1 coisa manual: rode  VencordInstaller  e clique Install."
echo " Depois:  sudo reboot"
echo " (a config antiga do CachyOS ficou em ~/.config/hypr.cachyos.bak)"
echo "============================================================"
