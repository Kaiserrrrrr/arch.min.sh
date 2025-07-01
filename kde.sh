#!/bin/bash

KDE_PACKAGES="xorg xorg-server plasma-desktop sddm dolphin konsole plasma-workspace"

# Function for error handling and exiting
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to ask for user confirmation
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

echo "--- KDE Plasma Setup Script ---"

if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root."
fi

echo "Updating system packages..."
pacman -Syu --noconfirm || error_exit "Failed to update system."

echo "Installing Xorg, KDE Plasma Desktop Environment, and SDDM Display Manager..."
echo "Packages to install: $KDE_PACKAGES"
pacman -S --noconfirm $KDE_PACKAGES || error_exit "Failed to install GUI packages."

echo "Enabling SDDM services..."
systemctl enable sddm || error_exit "Failed to enable SDDM display manager."

echo "--- KDE Plasma Minimal Setup Complete! ---"
echo "You can now reboot your system to log into the desktop."

confirm "Reboot now to start KDE Plasma?" && reboot || echo "Please manually reboot your system (e.g., 'reboot')."
