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
cd ~/
limactl --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
   if [ -d "$HOME/github.com" && ! -d "$HOME/github.com/lima" ]; then
	echo "Cloning lima into github.com directory"
	cd $HOME/github.com
	git clone https://github.com/lima-vm/lima.git
   elif [ -d "$HOME/github.com" && -d "$HOME/github.com/lima" && -z "$(ls -A $HOME/github.com/lima)" ]; then
	   cd $HOME/github.com
	   rm -r lima
	   git clone https://github.com/lima-vm/lima.git
	   echo "Cloning lima into github.com directory"
   else
	echo "Creating github.com"
	mkdir $HOME/github.com
	cd $HOME/github.com
	echo "Cloning lima into github.com directory"
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

# Create Ubuntu VM named ubuntu24 with template
limactl create --yes --name=ubuntu24 template:ubuntu-lts --cpus 8
if [ $? -ne 0 ]; then
  echo "Failed to create VM 'ubuntu24'."
  exit 1
fi
echo "VM 'ubuntu24' created successfully."

# Edit and start the VM with nested virtualization enabled
limactl edit ubuntu24 --start --set '.nestedVirtualization=true'
if [ $? -ne 0 ]; then
  echo "Failed to start and configure 'ubuntu24'."
  exit 1
fi
echo "'ubuntu24' started with nested virtualization enabled."

# Run ls -lta inside the VM
limactl shell ubuntu24 ls -lta
if [ $? -ne 0 ]; then
  echo "Failed to run 'ls -lta' inside 'ubuntu24'."
  exit 1
fi
echo "Command 'ls -lta' inside 'ubuntu24' executed successfully."

