#!/bin/bash

if [[ "$1" == "aarch64" ]]; then
    echo "Architecture is aarch64"
    CPU_ARCH="aarch64"
    GO_ARCH="arm64"
    KERNEL_ARCH="arm64"
elif [[ "$1" == "x86_64" ]]; then
    echo "Architecture is x86_64"
    CPU_ARCH="x86_64"
    GO_ARCH="amd64"
    KERNEL_ARCH="x86_64"
else
    echo "Unknown architecture: $1 - aarch64 or x86_64 supported"
    exit 1
fi

#check for go
go version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please install go - https://go.dev/doc/install.  Exiting.."
	exit 1
else
	echo "Go installed."
fi

#check for qemu
qemu-system-$HOSTTYPE --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please install QEMU.  Exiting.."
	exit 1
else
	echo "QEMU installed."
fi
 

#install lima

limactl --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
   if [ -d "$HOME/github.com" ]; then
	echo "Cloning lima into github.com folder"
	cd $HOME/github.com
	git clone https://github.com/lima-vm/lima.git
   else
	echo "Creating github.com"
	mkdir $HOME/github.com
	cd $HOME/github.com
	echo "Cloning lilma into github.com folder"
 	git clone https://github.com/lima-vm/lima.git
   fi
   cd $HOME/github.com/lima
   make
   sudo make install
   limactl --version > /dev/null 2>&1
   if [ $? -ne 0 ]; then
	   echo "Lima install failed"
	   exit 1
   else
	   echo "Lima installed"
   fi
else
   echo "Lima already installed"
fi


