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

#install arm64 toolchain
# sudo apt install -qy gcc-8-aarch64-linux-gnu g++-8-aarch64-linux-gnu gdb-multiarch

# need more proxy info for LR1
npm config set https-proxy http://proxy-ccy.houston.hpecorp.net:8080
npm config set proxy http://proxy-ccy.houston.hpecorp.net:8080

#Docker install - setup repo

sudo apt install -qy apt-transport-https ca-certificates curl gnupg-agent software-properties-common

#Docker install - add gpg key

cd ~

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Add docker repo apt sources
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt-get update

#Docker install

sudo apt install -qy docker-ce docker-ce-cli containerd.io docker-compose

#Install Go and set environment variables
cd /tmp
sudo wget https://go.dev/dl/go1.18.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.18.1.linux-amd64.tar.gz
sudo rm -rf *.*

#install pip and openssl stuff
sudo apt install -qy python-pip
sudo apt install -qy python3-pip
pip3 install --upgrade pip
pip3 install --upgrade setuptools
python3 -m pip install pyopenssl

#install powershell for linux
# Update the list of packages
sudo apt-get update
# Install pre-requisite packages.
sudo apt-get install -y wget apt-transport-https software-properties-common
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb
# Update the list of products
sudo apt-get update
# Enable the "universe" repositories
sudo add-apt-repository universe
# Install PowerShell
sudo apt-get install -y powershell







