#!/bin/bash
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

echo "--- Starting Arch Linux Installation Script ---"
echo "Verifying network connection..."
ping -c 3 archlinux.org || error_exit "No internet connection. Please connect to the internet and try again."
echo "Updating system clock..."
timedatectl set-ntp true || error_exit "Failed to set NTP."

# --- Get User Inputs ---
read -p "Enter desired hostname for your system (e.g., myarchvm): " HOSTNAME
if [ -z "$HOSTNAME" ]; then
    error_exit "Hostname cannot be empty."
fi

read -p "Enter desired username for your daily use (e.g., archuser): " USERNAME
if [ -z "$USERNAME" ]; then
    error_exit "Username cannot be empty."
fi

read -p "Enter desired SWAP partition size (e.g., 2G, 4G - leave empty for no swap): " SWAP_SIZE_INPUT
SWAP_SIZE=${SWAP_SIZE_INPUT:-"0"} # Default to 0 if empty, indicating no swap partition

# --- Partitioning ---
echo "--- Disk Partitioning ---"
echo "You need to MANUALLY partition your disk. Use 'cfdisk' or 'fdisk'."
echo "Identify your disk (e.g., /dev/sda, /dev/vda) using 'lsblk'."
lsblk
echo ""
read -p "Enter the disk you want to partition (e.g., /dev/sda): " DISK
if [ ! -b "$DISK" ]; then
    error_exit "$DISK is not a valid block device. Exiting."
fi
echo "Opening cfdisk for $DISK. Create your partitions NOW."
echo "Suggested Partitions (adjust sizes and types as needed):"
echo "  - EFI System Partition (for UEFI): 512MB, Type: EFI System (FAT32)"
if [ "$SWAP_SIZE" != "0" ]; then
    echo "  - Swap Partition: ${SWAP_SIZE}, Type: Linux swap"
fi
echo "  - Root Partition (/): Remaining space, Type: Linux filesystem (EXT4)"
echo "After partitioning, select 'Write', type 'yes', then 'Quit'."
echo ""
read -p "Press Enter to open cfdisk..."
cfdisk "$DISK" || error_exit "cfdisk failed. Partitioning aborted."
echo ""
echo "--- Partitioning Complete (Manual Step) ---"
echo "Listing new partitions:"
lsblk "$DISK"
echo ""

read -p "Enter the EFI System Partition (e.g., /dev/sda1): " EFI_PARTITION
read -p "Enter the ROOT Partition (e.g., /dev/sda3): " ROOT_PARTITION

# Prompt for SWAP only if size was provided
if [ "$SWAP_SIZE" != "0" ]; then
    read -p "Enter the SWAP Partition (e.g., /dev/sda2): " SWAP_PARTITION
    if [ ! -b "$SWAP_PARTITION" ]; then
        error_exit "$SWAP_PARTITION is not a valid block device. Please re-check your input."
    fi
fi

# Validate partitions
if [ ! -b "$EFI_PARTITION" ]; then
    error_exit "$EFI_PARTITION is not a valid block device. Please re-check your input."
fi
if [ ! -b "$ROOT_PARTITION" ]; then
    error_exit "$ROOT_PARTITION is not a valid block device. Please re-check your input."
fi


# --- Format Partitions ---
echo "--- Formatting Partitions ---"
echo "Formatting $EFI_PARTITION as FAT32..."
mkfs.fat -F32 "$EFI_PARTITION" || error_exit "Failed to format EFI partition."
if [ "$SWAP_SIZE" != "0" ]; then
    echo "Formatting $SWAP_PARTITION as swap and enabling..."
    mkswap "$SWAP_PARTITION" || error_exit "Failed to format swap partition."
    swapon "$SWAP_PARTITION" || error_exit "Failed to enable swap."
fi
echo "Formatting $ROOT_PARTITION as EXT4..."
mkfs.ext4 "$ROOT_PARTITION" || error_exit "Failed to format root partition."

# --- Mount Partitions ---
echo "--- Mounting Partitions ---"
echo "Mounting root partition to /mnt..."
mount "$ROOT_PARTITION" /mnt || error_exit "Failed to mount root partition."
echo "Creating /mnt/boot/efi and mounting EFI partition..."
mkdir -p /mnt/boot/efi || error_exit "Failed to create /mnt/boot/efi."
mount "$EFI_PARTITION" /mnt/boot/efi || error_exit "Failed to mount EFI partition."

# --- Base System Installation ---
echo "--- Installing Base System and Essential Packages ---"
PACKAGES="base linux linux-firmware nano grub efibootmgr networkmanager dialog curl"
pacstrap -K /mnt $PACKAGES || error_exit "Failed to install base packages."

echo "--- Generating fstab ---"
genfstab -U /mnt >> /mnt/etc/fstab || error_exit "Failed to generate fstab."
echo "fstab generated. Review with 'cat /mnt/etc/fstab' if needed after chroot."

# --- Chroot into New System and Configure ---
echo "--- Entering Chroot Environment for System Configuration ---"
arch-chroot /mnt /bin/bash <<EOF_CHROOT
echo "Inside chroot. Configuring system..."

# Auto-detect Timezone
echo "Attempting to auto-detect timezone via ipapi.co..."
DETECTED_TIMEZONE=$(curl -fsSL https://ipapi.co/timezone 2>/dev/null)
if [ -n "$DETECTED_TIMEZONE" ]; then
    echo "Detected timezone: $DETECTED_TIMEZONE"
    timedatectl set-timezone "$DETECTED_TIMEZONE" || echo "Warning: Failed to set timezone automatically. Please set it manually later if incorrect."
else
    echo "Could not auto-detect timezone. Falling back to interactive selection or default."
    echo "Available timezones (you can search by continent/city, e.g., 'America/New_York'):"
    timedatectl list-timezones | less
    read -p "Enter your desired timezone (e.g., Asia/Singapore, America/New_York): " MANUAL_TIMEZONE
    if [ -n "$MANUAL_TIMEZONE" ]; then
        timedatectl set-timezone "$MANUAL_TIMEZONE" || echo "Warning: Failed to set timezone to $MANUAL_TIMEZONE. Please set it manually later if incorrect."
    else
        echo "No timezone entered. Defaulting to system's current timezone (likely UTC)."
    fi
fi
hwclock --systohc || error_exit "Failed to sync hardware clock."


# Locale Configuration
echo "--- Locale Configuration ---"
echo "By default, common UTF-8 locales will be generated."
echo "You can choose your primary display language now."
echo "Common English locales:"
echo "1) en_US.UTF-8 (US English)"
echo "2) en_GB.UTF-8 (British English)"
echo "3) en_AU.UTF-8 (Australian English)"
echo "4) Skip (will default to en_US.UTF-8 as primary)"
read -p "Enter your choice (1-4): " LOCALE_CHOICE

PRIMARY_LOCALE="en_US.UTF-8" # Default fallback
case "$LOCALE_CHOICE" in
    1) PRIMARY_LOCALE="en_US.UTF-8" ;;
    2) PRIMARY_LOCALE="en_GB.UTF-8" ;;
    3) PRIMARY_LOCALE="en_AU.UTF-8" ;;
    *) echo "Invalid choice or skipped. Defaulting to en_US.UTF-8 as primary locale." ;;
esac

# Generate common UTF-8 locales by default
LOCALE_GEN_ENTRIES=(
    "en_US.UTF-8 UTF-8"
    "en_GB.UTF-8 UTF-8"
    "en_AU.UTF-8 UTF-8"
    "de_DE.UTF-8 UTF-8"
    "fr_FR.UTF-8 UTF-8"
    "es_ES.UTF-8 UTF-8"
    "ja_JP.UTF-8 UTF-8"
    "ko_KR.UTF-8 UTF-8"
    "zh_CN.UTF-8 UTF-8"
)

echo "" > /etc/locale.gen
for entry in "${LOCALE_GEN_ENTRIES[@]}"; do
    echo "$entry" >> /etc/locale.gen
done
echo "Generating locales..."
locale-gen || error_exit "Failed to generate locales."
echo "LANG=$PRIMARY_LOCALE" > /etc/locale.conf || error_exit "Failed to set LANG in locale.conf."
echo "System locale set to $PRIMARY_LOCALE."


echo "Setting hostname to $HOSTNAME..."
echo "$HOSTNAME" > /etc/hostname || error_exit "Failed to set hostname."

echo "Configuring /etc/hosts..."
cat <<EOL_HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL_HOSTS

echo "Setting root password..."
passwd || error_exit "Failed to set root password."

echo "Creating user '$USERNAME'..."
useradd -m -g users -G wheel,storage,power -s /bin/bash "$USERNAME" || error_exit "Failed to create user."
echo "Setting password for user '$USERNAME'..."
passwd "$USERNAME" || error_exit "Failed to set user password."

echo "Configuring sudo for wheel group..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers || error_exit "Failed to configure sudo."

echo "Installing and configuring GRUB bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable || error_exit "GRUB installation failed."
grub-mkconfig -o /boot/grub/grub.cfg || error_exit "GRUB configuration failed."

echo "Enabling NetworkManager service..."
systemctl enable NetworkManager || error_exit "Failed to enable NetworkManager."

echo "--- Installing XFCE and Display Manager ---"
XFCE_PACKAGES="xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
pacman -S --noconfirm $XFCE_PACKAGES || error_exit "Failed to install XFCE and display manager."

echo "Enabling LightDM display manager..."
systemctl enable lightdm || error_exit "Failed to enable LightDM."

echo "Exiting chroot environment..."
EOF_CHROOT

if [ $? -ne 0 ]; then
    error_exit "An error occurred inside the chroot environment. Installation aborted."
fi

echo "--- Finalizing Installation ---"
echo "Unmounting file systems..."
umount -R /mnt || error_exit "Failed to unmount /mnt. You may need to manually unmount."

echo "--- Installation Complete! ---"
echo "You can now reboot your system."
echo "After reboot, log in as '$USERNAME' with the password you set."
echo "You will be greeted by the XFCE desktop."

confirm "Reboot now?" && reboot || echo "Please manually reboot your system."