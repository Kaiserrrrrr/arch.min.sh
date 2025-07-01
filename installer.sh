#!/bin/bash

XFCE_PACKAGES="xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings networkmanager"

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

echo "--- Arch Linux Minimal GUI Setup Script ---"

if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root."
fi

echo "Verifying network connection..."
ping -c 3 archlinux.org || error_exit "No internet connection. Please ensure NetworkManager is running and you are connected."

echo "Updating system packages..."
pacman -Syu --noconfirm || error_exit "Failed to update system."

echo "Installing Xorg, XFCE desktop environment, and LightDM display manager..."
echo "Packages to install: $XFCE_PACKAGES"
pacman -S --noconfirm $XFCE_PACKAGES || error_exit "Failed to install GUI packages."

echo "Enabling NetworkManager and LightDM services..."
systemctl enable NetworkManager || echo "Warning: Failed to enable NetworkManager. Check your network setup."
systemctl enable lightdm || error_exit "Failed to enable LightDM display manager."

echo "--- GUI Setup Complete! ---"
echo "You can now reboot your system to log into the XFCE desktop."
echo "Login with the user you created during archinstall."

confirm "Reboot now to start XFCE?" && reboot || echo "Please manually reboot your system (e.g., 'reboot')."
