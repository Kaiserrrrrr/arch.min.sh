#!/bin/bash
PKG="plasma-desktop plasma-workspace sddm dolphin konsole spectacle kate chromium discord fastfetch htop hyprland"
err() { echo "ERROR: $1" >&2; exit 1; }
if [[ $EUID -ne 0 ]]; then err "This script must be run as root."; fi
pacman -Syu --noconfirm || err "Failed to update system."
pacman -S --noconfirm $PKG || err "Failed to install KDE packages."
systemctl enable sddm || err "Failed to enable SDDM display manager."
sh -c 'mkdir -p /etc/sddm.conf.d/ && echo -e "[Autologin]\nSession=hyprland.desktop" > /etc/sddm.conf.d/hyprland.conf' || err "Failed to set default SDDM session."
pacman -Sc; reboot
