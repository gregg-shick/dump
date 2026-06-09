#!/bin/bash
cd ~/
mkdir github.com
cd github.com
git clone https://github.com/cixtech/cix-linux-main
git clone --depth 1 https://github.com/torvalds/linux.git -b v7.0
cd linux
git branch cix
git checkout cix
git am ../cix-linux-main/patches-7.0/*.patch
cp ../cix-linux-main/config/config-7.0.defconfig .config
sed -i '$a\CONFIG_CMDLINE_BOOL=Y' .config
sed -i '$a\CONFIG_CMDLINE="clk_ignore_unused"' .config
make olddefconfig
make -j$(nproc) bindeb-pkg
