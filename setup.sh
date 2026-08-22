#!/usr/bin/env bash
# =============================================================================
# setup.sh — Nitro (RTX 4050 + Ryzen): Hyprland + Caelestia, espelhando o Luis.
# Rode DEPOIS do archinstall (profile Minimal), como USUÁRIO NORMAL (sem sudo).
# Uso:
#   nmcli device wifi connect "SSID" password "SENHA"
#   git clone https://github.com/SEU-USUARIO/nitro-setup.git
#   cd nitro-setup && ./setup.sh
# =============================================================================
set -euo pipefail

# diretório do repo (pra achar a pasta ./hypr)
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">> [1/6] yay (helper do AUR)"
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm git base-devel
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  ( cd "$tmp/yay" && makepkg -si --noconfirm )
fi

echo ">> [2/6] pacotes (repo + AUR)"
yay -S --needed --noconfirm --answerdiff=None --answerclean=None \
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  qt5-wayland qt6-wayland polkit-kde-agent foot firefox thunar gvfs \
  grim slurp wl-clipboard cliphist wtype brightnessctl playerctl pavucontrol \
  networkmanager network-manager-applet bluez bluez-utils blueman \
  power-profiles-daemon zram-generator sddm sddm-conf \
  noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono-nerd \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber gst-plugin-pipewire \
  linux-headers amd-ucode nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-prime egl-wayland \
  mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader vulkan-radeon lib32-vulkan-radeon \
  steam discord vencord-installer-bin onlyoffice-bin \
  qemu-full libvirt virt-manager edk2-ovmf dnsmasq swtpm dmidecode \
  caelestia-shell caelestia-cli hyprmod

echo ">> [3/6] NVIDIA: modeset + módulos no initramfs"
echo 'options nvidia_drm modeset=1' | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
  sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
fi
sudo mkinitcpio -P

echo ">> [4/6] copiar a config do hypr"
mkdir -p "$HOME/.config"
cp -r "$REPO/hypr" "$HOME/.config/"
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
sudo systemctl enable NetworkManager bluetooth sddm libvirtd
sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume
sudo usermod -aG libvirt "$USER"

echo
echo "============================================================"
echo " Tudo pronto!"
echo " Falta 1 coisa manual: rode  VencordInstaller  e clique Install."
echo " Depois:  sudo reboot"
echo "============================================================"
