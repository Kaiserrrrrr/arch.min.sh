#!/bin/bash
PKG="xorg xorg-server plasma-desktop plasma-workspace sddm dolphin konsole spectacle kate chromium fastfetch htop"
PKGDEL="avahi plasma5-desktop-emojier kwrite"
err() { echo "ERROR: $1" >&2; exit 1; }
if [[ $EUID -ne 0 ]]; then err "This script must be run as root."; fi
pacman -Syu --noconfirm || err "Failed to update system."
pacman -S --noconfirm $PKG || err "Failed to install KDE packages."
pacman -Rns --noconfirm $PKGDEL || err "Failed to uninstall bloatware."
systemctl enable sddm || err "Failed to enable SDDM display manager."
pacman -Sc; reboot
