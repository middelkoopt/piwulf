#!/bin/bash
set -e

SITE="./containers/warewulf/site.json"
PROFILE="nodes"

while (( $# )); do
  case $1 in
    --site=*)    SITE=${1#*=}; shift;;
    --profile=*) PROFILE=${1#*=}; shift;;
    --disk)      DISK=/dev/mmcblk0; shift;;
    --ipv6)      IPV6=1; shift;;
    *) break ;;
  esac
done

echo "=== setup-nodes.sh $SITE $PROFILE"

echo "--- Create profile"
sudo wwctl profile set --yes ${PROFILE} \
  --tagadd "Tag=rpi" \
  --kernelargs '"console=serial0,115200"' \
  --netdev=end0 \
  --netmask=255.255.0.0 --gateway=10.5.0.1 --nettagadd="DNS=10.5.0.1"

## IPv6
if [[ $IPV6 ]]; then
  echo "--- Setup IPv6"
  sudo wwctl profile set --yes ${PROFILE} \
    --prefixlen6=64 --gateway6=fd00:10:5::1 --nettagadd="DNS=fd00:10:5::1"
fi

## Two-stage provision to disk
if [[ $DISK ]]; then
  echo "--- Provision to disk $DISK"
  sudo wwctl profile set --yes ${PROFILE} \
    --diskname $DISK --diskwipe \
    --partname rootfs --partcreate --partnumber 1 \
    --fsname rootfs --fswipe --fsformat ext4 --fspath / \
    --root=/dev/disk/by-partlabel/rootfs
fi

echo "--- Create nodes"
for n in $(jq -r ".nodes | keys[]" $SITE) ; do
  serial=$(jq -r ".nodes.${n}.serial" $SITE)
  mac=$(jq -r ".nodes.${n}.mac" $SITE)
  i=$((i+1))
  sudo wwctl node delete --yes ${n} || true
  sudo wwctl node add ${n} --profile=${PROFILE}
  sudo wwctl node set --yes ${n} \
    --tagadd="Serial=${serial: -8}" \
    --hwaddr=${mac} \
    --ipaddr=10.5.1.${i}
  if [[ $IPV6 ]]; then
    sudo wwctl node set --yes ${n} \
      --ipaddr6="fd00:10:5::1:${i}"
  fi
done

echo "--- Reconfigure warewulf and build overlays"
sudo wwctl configure --all
sudo wwctl overlay build
