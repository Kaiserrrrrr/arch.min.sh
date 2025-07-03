#!/bin/bash
PKG="xorg xorg-server plasma-desktop plasma-workspace sddm dolphin konsole spectacle kate chromium discord fastfetch htop"
err() { echo "ERROR: $1" >&2; exit 1; }
if [[ $EUID -ne 0 ]]; then err "This script must be run as root."; fi
pacman -Syu --noconfirm || err "Failed to update system."
pacman -S --noconfirm $PKG || err "Failed to install KDE packages."
systemctl enable sddm || err "Failed to enable SDDM display manager."
pacman -Sc; reboot
