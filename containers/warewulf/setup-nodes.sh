#!/bin/bash
set -e

: ${SITE:=site.json}

echo "=== setup-nodes.sh"

## Create profile
wwctl profile delete --yes nodes || true
wwctl profile add nodes --profile default --image nodeimage
wwctl profile set --yes nodes \
  --tagadd "Firmware=efi" \
  --kernelargs '"console=serial0,115200"' \
  --netdev=end0 \
  --netmask=255.255.0.0 --gateway=10.5.0.1 --nettagadd="DNS=10.5.0.1" \
  --prefixlen6=64 --gateway6=fd00:10:5::1 --nettagadd="DNS=fd00:10:5::1"

## Add to-stage provision to disk
wwctl profile set --yes nodes \
  --diskname /dev/mmcblk0 --diskwipe \
  --partname rootfs --partcreate --partnumber 1 \
  --fsname rootfs --fswipe --fsformat ext4 --fspath / \
  --root=/dev/disk/by-partlabel/rootfs 

## Create nodes
for n in $(jq -r ".nodes | keys[]" $SITE) ; do
  serial=$(jq -r ".nodes.${n}.serial" $SITE)
  mac=$(jq -r ".nodes.${n}.mac" $SITE)
  i=$((i+1))
  wwctl node delete --yes ${n} || true
  wwctl node add ${n} --profile=nodes 
  wwctl node set --yes ${n} \
    --tagadd="Serial=${serial: -8}" \
    --hwaddr=${mac} \
    --ipaddr=10.5.1.${i} \
    --ipaddr6="fd00:10:5::1:${i}"
done

## Import overlays
for I in *.ww ; do
  wwctl overlay import --overwrite host $I /var/lib/tftpboot/
done

## Reconfigure warewulf and build overlays
wwctl configure --all
wwctl overlay build
