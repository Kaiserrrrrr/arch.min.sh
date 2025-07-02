#!/bin/bash

KDE_PACKAGES="xorg xorg-server plasma-desktop sddm dolphin konsole plasma-workspace"

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

echo "You can now reboot your system to log into KDE Plasma."
confirm "Reboot now to start KDE Plasma?" && reboot || echo "Please manually reboot your system (e.g., 'reboot')."
