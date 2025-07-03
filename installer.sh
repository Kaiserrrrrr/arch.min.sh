#!/bin/bash

ARCHINSTALL_CONFIG_URL="https://raw.githubusercontent.com/Kaiserrrrrr/arch.min.sh/main/user_configuration.json"
LOCAL_CONFIG_FILE="/tmp/user_configuration.json"

err() {
    echo "ERROR: $1" >&2
    exit 1
}

get_confirmation() {
    read -p "$1 (y/N): " -n 1 -r
    echo "" # Newline after input
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0 # True
    else
        return 1 # False
    fi
}

get_user_timezone() {
    local TZ=""

    if ! command -v curl &> /dev/null; then
        pacman -Sy curl --noconfirm &>/dev/null || true 
    fi

    if command -v curl &> /dev/null; then
        DETECTED_TZ=$(curl -s "http://ip-api.com/json" | jq -r '.timezone' 2>/dev/null)
        if [ -n "$DETECTED_TZ" ] && [ "$DETECTED_TZ" != "null" ]; then
            get_confirmation "Detected timezone: $DETECTED_TZ. Use this timezone?"
            if [[ $? -eq 0 ]]; then
                TZ="$DETECTED_TZ"
            fi
        fi
    fi

    # Fallback to manual prompt if TZ not set or declined
    while [ -z "$TZ" ]; do
        read -p "Enter timezone (e.g., 'America/New_York' or 'Asia/Singapore'). List with 'timedatectl list-timezones': " USER_INPUT_TZ

        if [ -n "$USER_INPUT_TZ" ]; then
            if timedatectl list-timezones | grep -q -x "$USER_INPUT_TZ"; then
                TZ="$USER_INPUT_TZ"
            else
                echo "Invalid timezone: '$USER_INPUT_TZ'. Please try again."
            fi
        fi
    done
    echo "$TZ"
}

if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root."
fi


if ! command -v jq &> /dev/null; then
    pacman -Sy jq --noconfirm &>/dev/null || err "Failed to install jq for JSON manipulation."
fi

curl -o "$LOCAL_CONFIG_FILE" "$ARCHINSTALL_CONFIG_URL" &>/dev/null || err "Failed to download config file from URL. Check URL or internet."

SELECTED_TIMEZONE=$(get_user_timezone)

jq --arg tz "$SELECTED_TIMEZONE" '.timezone = $tz' "$LOCAL_CONFIG_FILE" > "${LOCAL_CONFIG_FILE}.tmp" && mv "${LOCAL_CONFIG_FILE}.tmp" "$LOCAL_CONFIG_FILE" || err "Failed to update timezone in config file."

archinstall --config "$LOCAL_CONFIG_FILE" || err "Archinstall failed. Check /var/log/archinstall/install.log for details."
