#!/bin/bash
err() { echo "ERROR: $1" >&2; exit 1 }
if [[ $EUID -ne 0 ]]; then err "This script must be run as root."; fi
pacman -Syu --noconfirm || err "Failed to update system."
pacman -S --noconfirm "xorg xorg-server xfce4 lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings chromium fastfetch" || err "Failed to install XFCE packages."
pacman -S --noconfirm --needed $(pacman -Sgq xfce4-goodies | grep -v -E "^(parole|xfburn|xfce4-dict)$") || err "Failed to install XFCE goodies"
systemctl enable lightdm || err "Failed to enable LightDM display manager."
reboot
