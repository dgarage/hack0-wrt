#!/bin/sh /etc/rc.common

START=99

start() {
    if ls /*.rom > /dev/null 2>&1; then
        ROM_FILE="$(echo /*.rom)"
        echo "ROM file detected: $ROM_FILE"
        if ! flashrom -p internal --verify "$ROM_FILE"; then
            echo "Flashing..."
            if flashrom -p internal --write "$ROM_FILE"; then
                rm "$ROM_FILE"
                reboot
            else
                echo "Failure to flash the rom"
            fi
        else
            rm "$ROM_FILE"
            echo "The ROM is already flashed"
        fi
    fi
}