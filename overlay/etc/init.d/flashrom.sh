#!/bin/sh /etc/rc.common

START=99

start() {
    # This script look for a rom file on '/' then verify it is flashed on the device
    if ls /*.rom > /dev/null 2>&1; then
        ROM_FILE="$(echo /*.rom)"
        echo "ROM file detected: $ROM_FILE"
        # If not the device is not flashed with it, flash it
        if ! flashrom -p internal --verify "$ROM_FILE"; then
            echo "Flashing..."
            if flashrom -p internal --write "$ROM_FILE"; then
                # If flash is successfull, remove the rom file and reboot
                rm "$ROM_FILE"
                reboot
            else
                # If flash is not successfull, continue...
                echo "Failure to flash the rom"
            fi
        # If the device is already flashed, just remove the ROM file and carry on.
        else
            rm "$ROM_FILE"
            echo "The ROM is already flashed"
        fi
    fi
}