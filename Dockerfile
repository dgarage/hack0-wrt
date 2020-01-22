FROM debian:buster-slim

RUN apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install -y subversion g++ zlib1g-dev build-essential git python python3 \
                       libncurses5-dev gawk gettext unzip file libssl-dev wget \
                       libelf-dev ecj fastjar java-propose-classpath \
                       python3-distutils \
                       # make kernel_menuconfig fails if not running with another user
                       sudo \
                       unzip && \
    apt-get clean


# make kernel_menuconfig fails if not running with another user
RUN useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' >> /etc/sudoers
USER user
WORKDIR /home/user


ENV OPEN_WRT_TAG=v19.07.0
RUN git clone --depth 1 --branch "$OPEN_WRT_TAG" https://github.com/openwrt/openwrt

WORKDIR /home/user/openwrt

# Update feed, and apply patches to get the latest version of coovachilli (1.5.2 instead of 1.4)
RUN ./scripts/feeds update -a && \
    cd feeds/packages && \
    git fetch && \
    git diff HEAD e154fc473c0fcd3da8ad7b43f489ff48745e6dfe -- net/coova-chilli/ | git apply --whitespace=nowarn && \
    cd .. && \
    ./scripts/feeds install -a

ARG DEV=false
# Our config does what "make menuconfig" would do if:
# * Setup openwrt for target x86, subtarget x86_64
# * In Target Images check ext4 and Build GRUB images
# Also add all the kernel modules documented at https://openwrt.org/toh/pcengines/apu2#kernel_modules
# Needed to boot OpenWrt from SD card: https://github.com/pcengines/apu2-documentation/blob/master/docs/debug/openwrt.md
COPY menuconfig.diff .config
RUN sudo chown user:user .config && \
    make defconfig && \
    # download all dependency source files before final make, enables multi-core compilation
    make download && \
    # [kernel-]menuconfig, this will make it faster to do if we compile that now
    ( ! $DEV || make tools/quilt/compile )

# Our Kernel changes are doing what "make kernel_menuconfig" if:
# * Go into Device Drivers → MMC/SD/SDIO
# * Enable MMC block device driver, Secure Digital Host Controller Interface support, SDHCI support on PCI bus
# Needed to boot OpenWrt from SD card: https://github.com/pcengines/apu2-documentation/blob/master/docs/debug/openwrt.md
COPY kernel-menuconfig.patch .
RUN git apply kernel-menuconfig.patch

ENV APU_FIRMWARE="https://3mdeb.com/open-source-firmware/pcengines/apu4/apu4_v4.11.0.2.rom"
ENV APU_FIRMWARE_HASH="536c504e5e2b679fed38aea20953f6044cc171a65631e1316309ec20b9a0280c  apu4_v4.11.0.2.rom"
RUN mkdir -p files && \
    cd files && wget -q "${APU_FIRMWARE}" && \
    echo "$APU_FIRMWARE_HASH" | sha256sum -c -
COPY overlay/ files/
ARG MAKE_ARGS=""
RUN make ${MAKE_ARGS}

USER root
COPY docker-entrypoint.sh .
ENTRYPOINT [ "./docker-entrypoint.sh" ]