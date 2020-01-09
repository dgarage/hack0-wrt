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


ENV OPEN_WRT_TAG=v18.06.5
RUN git clone --depth 1 --branch "$OPEN_WRT_TAG" https://github.com/openwrt/openwrt

WORKDIR /home/user/openwrt
RUN ./scripts/feeds update -a && ./scripts/feeds install -a

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
ARG MAKE_ARGS=""
RUN make ${MAKE_ARGS}

USER root
COPY docker-entrypoint.sh .
ENTRYPOINT [ "./docker-entrypoint.sh" ]