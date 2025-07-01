#!/bin/bash

XFCE_PACKAGES="xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"

error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

confirm() {
    read -r -p "$1 (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

echo "--- XFCE Setup Script ---"

if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root."
fi

echo "Updating system packages..."
pacman -Syu --noconfirm || error_exit "Failed to update system."

echo "Installing Xorg, XFCE Desktop Environment, and LightDM Display Manager..."
echo "Packages to install: $XFCE_PACKAGES"
pacman -S --noconfirm $XFCE_PACKAGES || error_exit "Failed to install GUI packages."

echo "Enabling LightDM services..."
systemctl enable lightdm || error_exit "Failed to enable LightDM display manager."

echo "--- GUI Setup Complete! ---"
echo "You can now reboot your system to log into the desktop."

confirm "Reboot now to start XFCE?" && reboot || echo "Please manually reboot your system (e.g., 'reboot')."
