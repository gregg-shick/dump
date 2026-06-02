#!/bin/bash
is_ready=true

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
	echo "Please install go - https://go.dev/doc/install."
	is_ready=false
else
	echo "Go installed."
fi

#check for qemu
qemu-system-$HOSTTYPE --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please install QEMU."
	is_ready=false
else
	echo "QEMU installed."
fi
 
#check for build_essential
make --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please install build-essential."
	is_ready=false
else
	echo "build-essential installed."
fi

#check for kvm
#
if [-d "/dev/kvm" ]; then
	echo "KVM installed"
else
	echo "Please install KVM"
	is_ready=false
fi 


if $is_ready; then
	echo "Required tools installed"
else
	echo "Missing required tools.  Exiting"
	exit 1
fi


#install lima
cd ~/
limactl --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
   if [[ ! -d "$HOME/github.com" ]]; then
        echo "first if"
	echo "Creating github.com"
	mkdir $HOME/github.com
	cd $HOME/github.com
	echo "Cloning lima into github.com directory"
	git clone https://github.com/lima-vm/lima.git
	read -p "enter"
   elif [[ -d "$HOME/github.com" && ! -d "$HOME/github.com/lima" ]]; then
	echo "I am in first elif"
	echo "Cloning liima into github.com directory"
	cd $HOME/github.com
	git clone https://github.com/lima-vm/lima.git
	read -p "enter"
   elif [[ -d "$HOME/github.com" && -d "$HOME/github.com/lima" && -z "$(ls "$HOME/github.com/lima")" ]]; then
        echo "second elif"
	cd $HOME/github.com
	rm -rf lima
	echo "Cloning lima into github.com directory"
	git clone https://github.com/lima-vm/lima.git
	read -p "enter"
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

run_command() {
  echo "Run_Command"
  limactl shell ubuntu24 "$@"
  echo "command done"
  cmd_status=$?
  if [ "$cmd_status" -ne "0" ]; then
    echo "Command '$*' failed with exit code $cmd_status."
    exit $cmd_status
  else
    echo "Command '$*' succeeded."
  fi
}

run_command sudo dmesg
echo "Done"
run_command ls -lt
# run_command bash -c "cd ~ && pwd && wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.12.tar.xz"
# run_command bash -c "cd ~ && xz -d linux-6.1.12.tar.xz && tar xf linux-6.1.12.tar"
# run_command bash -c "cd ~ && rm linux-6.1.12.tar"
run_command bash -c "sudo apt -y install golang"
run_command bash -c "cd ~ && git clone --depth 1 https://github.com/firecracker-microvm/firecracker"
# We can build with TARGET_CC=x86_64-linux-musl-gcc cargo build --release --target x86_64-unknown-linux-musl
# But first we need to build x86 cross compiler on aarch64 and install it to the relevant place
run_command bash -c "cd ~ && git clone --depth 1 https://github.com/vejmarie/musl-cross-make.git"
# run_command bash -c "cd ~ && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.88.0"
# run_command bash -c "cd ~ && rustup toolchain install 1.88.0"
# . "$HOME/.cargo/env"
# run_command bash -c "cd ~ && rustup default 1.88.0"
# rustup target add x86-64-unknown-linux-musl
# 
run_command bash -c "sudo apt -y install make"
run_command bash -c "cd ~ && cd musl-cross-make && cat Makefile | sed 's/GNU_SITE = .*/GNU_SITE = https:\/\/mirror.cs.odu.edu\/gnu\//' > Makefile.New && cp Makefile.New Makefile  && make TARGET=$CPU_ARCH-linux-musl -j 8"
# We need to build for arm and x86_64
# we need to find a way to get a config.mk
run_command bash -c "cd ~ && cd musl-cross-make && echo 'TARGET = '$CPU_ARCH'-linux-musl' > config.mak && echo 'OUTPUT = /usr/local' >> config.mak && sudo make install"
# make TARGET=x86_64-linux-musl -j 8
run_command bash -c "cd ~ && wget https://github.com/seccomp/libseccomp/releases/download/v2.6.0/libseccomp-2.6.0.tar.gz && gunzip libseccomp-2.6.0.tar.gz && tar xf libseccomp-2.6.0.tar"
run_command bash -c "sudo apt -y install gperf"
# CFLAGS="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -O2" ./configure --host=x86_64-linux-gnu --enable-static --disable-shared
run_command bash -c 'cd ~/libseccomp-2.6.0 && export CC='$CPU_ARCH'-linux-musl-gcc && CFLAGS="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -O2" ./configure --host='$CPU_ARCH'-linux-musl --enable-static --disable-shared && make -j 8'
run_command bash -c 'cd ~/libseccomp-2.6.0 && sudo cp ./src/.libs/libseccomp.a /usr/local/lib'
# Install src/.libs/libseccomp.a into /usr/local/lib
# compile firecracker
if [[ "$CPU_ARCH" = "aarch64" ]]
then
	run_command bash -c "cd ~/firecracker && sudo apt -y install libseccomp-dev rustup && rustup default stable && TARGET_CC=$CPU_ARCH-linux-musl-gcc cargo build --release --target $CPU_ARCH-unknown-linux-musl"
else
	run_command bash -c "cd ~/firecracker && sudo apt -y install libseccomp-dev rustup && rustup default stable && export CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=x86_64-linux-musl-ld && sudo ln -s /usr/local/x86_64-linux-musl/include/asm /usr/include/asm && TARGET_CC=$CPU_ARCH-linux-musl-gcc cargo build --release --target $CPU_ARCH-unknown-linux-musl"
fi
# TARGET_CC=x86_64-linux-musl-gcc cargo build --release --target x86_64-unknown-linux-musl

run_command bash -c "cd ~/firecracker && sudo strip build/cargo_target/$CPU_ARCH-unknown-linux-musl/release/firecracker"
run_command bash -c "cp ~/firecracker/build/cargo_target/$CPU_ARCH-unknown-linux-musl/release/firecracker /tmp"
run_command bash -c "cp uinit ~/ && cd ~ && git clone --depth 1 https://github.com/u-root/u-root && cd u-root && go build . && cp ~/uinit . && chmod 755 ./uinit && GOOS=linux GOARCH=$GO_ARCH ./u-root -files "./uinit" -uinitcmd 'gosh uinit' -o initramfs"
run_command bash -c "cd ~/u-root && mkdir tmp && cd tmp && sudo cpio -idv < ../initramfs && sudo cp /tmp/firecracker bin/firecracker && (find . | sudo cpio -H newc -o > ../initramfs.cpio)"
run_command bash -c "cd ~ && sudo apt -y install make gcc flex bison libssl-dev"
run_command bash -c "cd ~ && pwd && wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.12.tar.xz"
run_command bash -c "cd ~ && xz -d linux-6.1.12.tar.xz && tar xf linux-6.1.12.tar"
run_command bash -c "cd ~ && rm linux-6.1.12.tar"
run_command bash -c "cp defconfig_arm64 ~/ && cp defconfig_x86_64 ~/ && cd ~ && cd linux-6.1.12 && cp ../defconfig_arm64 . && cp ../defconfig_x86_64 . && make ARCH=$KERNEL_ARCH CROSS_COMPILE=$CPU_ARCH-linux-musl- allnoconfig && export ARCH=$KERNEL_ARCH && export CROSS_COMPILE=$CPU_ARCH-linux-musl- && scripts/kconfig/merge_config.sh .config defconfig_${KERNEL_ARCH} && sudo apt -y install libelf-dev && make -j 8 ARCH=$KERNEL_ARCH CROSS_COMPILE=$CPU_ARCH-linux-musl-"
run_command bash -c "cd ~ && git clone --depth 1 https://github.com/linuxboot/fiano.git && cd fiano/cmds/create-ffs && go build && if [ -f ../../../linux-6.1.12/arch/$KERNEL_ARCH/boot/bzImage ]; then cp ../../../linux-6.1.12/arch/$KERNEL_ARCH/boot/bzImage ../../../linux-6.1.12/arch/$KERNEL_ARCH/boot/Image; fi && cp ../../../linux-6.1.12/arch/$KERNEL_ARCH/boot/Image . && ./create-ffs -guid 7C04A583-9E3E-4F1C-AD65-E05268D0B4D1 -xzPath /usr/bin/xz -type APPLICATION -d -o shell.ffs ./Image && mkdir ~/output && cp ./Image ~/output && cp ./shell.ffs ~/output"
echo "All commands executed successfully."
# limactl copy ubuntu24:~/linux-6.1.12/arch/rm64/boot/Image .
# to add network -nic user,model=virtio-net-pci
# to add random generator -object rng-random,id=host_rng,filename=/dev/urandom -device virtio-rng-pci,rng=host_rng
# init: 1970/01/01 00:00:00 Setting console log level to 5...
# $
# $
# $ dhclient -ipv6=false eth0
# 1970/01/01 00:00:11 Bringing up interface eth0...
# 1970/01/01 00:00:11 Attempting to get DHCPv4 lease on eth0
# 1970/01/01 00:00:11 Got DHCPv4 lease on eth0: DHCPv4 Message
#   opcode: BootReply
#   hwtype: Ethernet
#   hopcount: 0
#   transaction ID: 0x2b327116
#   num seconds: 0
#   flags: Unicast (0x00)
#   client IP: 0.0.0.0
#   your IP: 192.168.2.2
#   server IP: 192.168.2.1
#   gateway IP: 0.0.0.0
#   client MAC: 52:54:00:12:34:56
#   server hostname: HPE-GFG4L6FH3Q
#   bootfile name:
#   options:
#     Subnet Mask: ffffff00
#     Router: 192.168.2.1
#     Domain Name Server: 192.168.2.1
#     Domain Name: attlocal.net
#     IP Addresses Lease Time: 1h0m0s
#     DHCP Message Type: ACK
#     Server Identifier: 192.168.2.1
# 1970/01/01 00:00:11 Configured eth0 with IPv4 DHCP Lease IP 192.168.2.2/24
# 1970/01/01 00:00:11 Finished trying to configure all interfaces.
# $ ping 192.168.2.1
# 64 bytes from 192.168.2.1: icmp_seq=1 time=388.708µs
# 64 bytes from 192.168.2.1: icmp_seq=2 time=210.042µs
# 64 bytes from 192.168.2.1: icmp_seq=3 time=207.166µs
# 64 bytes from 192.168.2.1: icmp_seq=4 time=212.917µs
# $ ntpdate
# 2026/05/27 16:25:47 adjust time server time.google.com offset +1779899111.888302 sec
# $ date
# Wed May 27 16:25:50 GMT 2026
# $
# mkdir -p /tmp/firecracker
# chmod 755 /tmp/firecracker
# firecracker --api-sock /tmp/firecracker/socket
# qemu-system-aarch64  -cpu max -M virt -m 2048 -machine virt,accel=hvf,highmem=off -bios /opt/homebrew/Cellar/qemu/11.0.0/share/qemu/edk2-aarch64-code.fd  -smp 1 -kernel ./Image -append "console=ttyS0" -boot d -nodefaults -serial stdio
# qemu-system-aarch64  -cpu max -M virt -m 2048 -machine virt,accel=hvf,highmem=off -bios /opt/homebrew/Cellar/qemu/11.0.0/share/qemu/edk2-aarch64-code.fd  -smp 1 -kernel ./Image -append "console=ttyAMA0 earlycon=pl011,0x09000000" -boot d -nodefaults -serial stdio
# qemu-system-x86_64 -kernel ./Image.x86 -append console=ttyS0 earlyprintk=ttyS0 -nographic
