#!/bin/bash

KDE_PACKAGES="xorg xorg-server plasma-desktop plasma-workspace sddm dolphin konsole spectacle kwrite"

error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root."
fi

pacman -Syu --noconfirm || error_exit "Failed to update system."
pacman -S --noconfirm $KDE_PACKAGES || error_exit "Failed to install KDE packages."
systemctl enable sddm || error_exit "Failed to enable SDDM display manager."
reboot
