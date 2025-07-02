#!/bin/bash

XFCE_PACKAGES="xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"

error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root."
fi

pacman -Syu --noconfirm || error_exit "Failed to update system."
pacman -S --noconfirm $XFCE_PACKAGES || error_exit "Failed to install XFCE packages."
systemctl enable lightdm || error_exit "Failed to enable LightDM display manager."

echo "You can now reboot your system to log into XFCE."
confirm "Reboot now to start XFCE?" && reboot || echo "Please manually reboot your system (e.g., 'reboot')."
