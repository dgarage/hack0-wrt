#!/bin/bash
set -e

IMAGE="bin/targets/x86/64/openwrt-x86-64-combined-ext4.img"
if [[ "$1" == "deploy" ]]; then
    dd bs=8M "if=$IMAGE" "of=$2"
elif [[ "$1" == "extract" ]]; then
    cp -rf "bin/targets/x86/64/openwrt-x86-64-combined-ext4.img" /opt/bin/
fi
