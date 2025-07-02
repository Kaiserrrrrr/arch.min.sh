#!/bin/bash

error_exit() { echo "ERROR: $1" >&2;; exit 1 }

if [[ $EUID -ne 0 ]]; then error_exit "This script must be run as root."; fi

pacman -Syu --noconfirm || error_exit "Failed to update system."
pacman -S --noconfirm "xorg xorg-server xfce4 lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings fastfetch" || error_exit "Failed to install XFCE packages."
pacman -S --noconfirm --needed $(pacman -Sgq xfce4-goodies | grep -v -E "^(parole|xfburn|xfce4-dict)$") || error_exit "Failed to install XFCE Goodies"
systemctl enable lightdm || error_exit "Failed to enable LightDM display manager."
reboot
