#!/bin/bash
set -e

## Config
: ${IMAGE:=${1:-nodeimage}}
: ${PROFILE:=${2:-nodes}}
: ${WW_VERSION:=${2:-4.6.4}}
: ${OS_RELEASE:=10}
: ${FIRMWARE:=efi}

echo "=== setup-image.sh $IMAGE $PROFILE $WW_VERSION"

## Import base image
wwctl image import --build=false docker://ghcr.io/warewulf/warewulf-rockylinux:${OS_RELEASE} ${IMAGE}

## Setup image
wwctl image exec ${IMAGE} --build=false -- /bin/bash -xe <<EOF
## Remove unneeded packages
dnf remove -y kernel-core

## Setup Rocky
dnf update -y
dnf install -y dnf-utils epel-release rocky-release-rpi
dnf config-manager --set-enabled crb
dnf update -y

## Install and configure dracut and dependencies first (reduce build time)
dnf install -y dracut ignition gdisk
echo 'hostonly="no"' > /etc/dracut.conf.d/wwinit.conf
echo 'add_dracutmodules+=" wwinit ignition "' >> /etc/dracut.conf.d/wwinit.conf

## Install warewulf-dracut
dnf install -y https://github.com/warewulf/warewulf/releases/download/v${WW_VERSION}/warewulf-dracut-${WW_VERSION}-1.EL${OS_RELEASE}.noarch.rpm

## Install RPi kernel
dnf install -y --setopt=install_weak_deps=False kernel-rpi-4k-core kernel-rpi-firmware rpi-firmware-bluez rpi-firmware-nonfree

## Install tools
dnf install -y \
  ca-certificates procps zstd jq yq \
  initscripts-service cpio pigz \
  openssh openssh-clients openssh-server iproute iputils NetworkManager sudo \
  bind-utils nfs-utils systemd-timesyncd \
  nano vim less bash-completion man

## FIXME: Reinstall packages that require capabilities (required for podman)
RUN dnf reinstall -y shadow-utils

## Configure boot
chmod 644 /boot/efi/initramfs8

## Configure login
passwd -d root
sed -i '/alias/d' /root/.bashrc
EOF

## Setup profile
wwctl profile add ${PROFILE} --profile default || true
wwctl profile set --yes ${PROFILE} --image ${IMAGE}
wwctl profile set --yes ${PROFILE} --tagadd "Firmware=${FIRMWARE}"

## Build image
wwctl image build ${IMAGE}
