#!/bin/bash

## Config
OS_RELEASE=10
WW_VERSION=4.6.4

## Import base image
wwctl image import --build=false docker://ghcr.io/warewulf/warewulf-rockylinux:${OS_RELEASE} nodeimage

## Setup image
wwctl image exec nodeimage --build=false -- /bin/bash -xe <<EOF
## Remove unneeded packages
dnf remove -y kernel-core

## Setup Rocky
dnf update -y
dnf install -y dnf-utils epel-release rocky-release-rpi
dnf config-manager --set-enabled crb
dnf update -y

## Install RPi kernel
dnf install -y kernel-rpi-4k-core kernel-rpi-firmware rpi-firmware-bluez rpi-firmware-nonfree

## Install tools
dnf install -y \
  ca-certificates procps zstd jq yq \
  initscripts-service cpio pigz \
  openssh openssh-clients openssh-server iproute iputils NetworkManager sudo \
  nano vim less bash-completion man

## Configure system
passwd -d root
sed -i '/alias/d' /root/.bashrc
EOF

## Setup dracut for disk provisioning
wwctl image exec nodeimage --build=false -- /bin/bash -ex <<EOF
## Install Dracut
dnf install -y https://github.com/warewulf/warewulf/releases/download/v${WW_VERSION}/warewulf-dracut-${WW_VERSION}-1.EL${OS_RELEASE}.noarch.rpm

# configure dracut for provisoin to disk
echo 'hostonly="no"' > /etc/dracut.conf.d/wwinit.conf
echo 'add_dracutmodules+=" wwinit ignition "' >> /etc/dracut.conf.d/wwinit.conf

# install disk tools
dnf install -y ignition gdisk

# build dracut
dracut --force /boot/efi/initramfs8
chmod 644 /boot/efi/initramfs8
EOF

## Build image
wwctl image build nodeimage
