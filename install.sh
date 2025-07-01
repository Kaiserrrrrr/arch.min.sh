#!/bin/bash

set -x

XFCE_PACKAGES="xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
KDE_PACKAGES="xorg xorg-server plasma-desktop sddm dolphin konsole plasma-wayland-session"

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

echo "--- Arch Linux GUI Setup Script ---"

if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root."
fi

echo "Updating system packages..."
pacman -Syu --noconfirm || error_exit "Failed to update system."

DESKTOP_ENV=""
while true; do
    echo "Which desktop environment would you like to install?"
    echo "1) XFCE"
    echo "2) KDE Plasma (Minimal)"
    read -r -p "Enter your choice (1 or 2): " choice

    printf "DEBUG: You entered '%s' (length: %d)\n" "$choice" "${#choice}"
    
    choice=$(echo "$choice" | tr -d '[:space:]')

    case "$choice" in
        1)
            DESKTOP_ENV="XFCE"
            PACKAGES_TO_INSTALL="$XFCE_PACKAGES"
            DISPLAY_MANAGER="lightdm"
            break 
            ;;
        2)
            DESKTOP_ENV="KDE Plasma"
            PACKAGES_TO_INSTALL="$KDE_PACKAGES"
            DISPLAY_MANAGER="sddm"
            break 
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            ;;
    esac
done

echo "You have chosen to install $DESKTOP_ENV."

echo "Installing Xorg, $DESKTOP_ENV, and $DISPLAY_MANAGER..."
echo "Packages to install: $PACKAGES_TO_INSTALL"
pacman -S --noconfirm $PACKAGES_TO_INSTALL || error_exit "Failed to install $DESKTOP_ENV packages."

echo "Enabling $DISPLAY_MANAGER service..."
systemctl enable "$DISPLAY_MANAGER" || error_exit "Failed to enable $DISPLAY_MANAGER display manager."

echo "--- $DESKTOP_ENV Setup Complete! ---"
echo "You can now reboot your system to log into the desktop."
echo "REMINDER: You will need to manually configure your network connection."

confirm "Reboot now to start $DESKTOP_ENV?" && reboot || echo "Please manually reboot your system (e.g., 'reboot')."
