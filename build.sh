#!/bin/bash

#Install required build packages even though the build environment will be docker based.  Taken from docker build file.  
sudo apt install -qy ca-certificates
sudo apt install -qy build-essential apt-utils libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip wget snapd squashfuse fuse
sleep 2
sudo apt install -qy snap-confine sudo python2.7-dev chrpath cpio diffstat gawk texinfo python3.8 python3.8-venv python3.8-distutils 
sleep 2
sudo apt install -qy python3.8-dev python3.8-gdbm python3.8-tk python3.8-lib2to3 idle-python3.8 flex bison libncurses-dev vim openssl 
sleep 2
sudo apt install -qy dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf bc libtirpc-dev
sleep 2
sudo apt install -qy libsdl1.2-dev qemu-system-arm open-vm-tools socat chrpath diffstat flex bison libncurses-dev jq 
sleep 2
sudo apt install -qy libusb-1.0-0-dev libusb-dev libcurl4-openssl-dev pkg-config
sudo apt install -qy libssl1.0-dev npm
sudo apt install -qy liblz4-tool zstd libgnutls28-dev







