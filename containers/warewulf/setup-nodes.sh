#!/bin/bash
set -e

# Simplified version of ./scripts/setup-nodes.sh for iso

: ${SITE:=site.json}

echo "=== setup-nodes.sh $SITE"

echo "--- Create profile"
wwctl profile delete --yes nodes || true
wwctl profile add nodes --profile default --image nodeimage
wwctl profile set --yes nodes \
  --tagadd "Firmware=efi" \
  --kernelargs '"console=serial0,115200"' \
  --netdev=end0 \
  --netmask=255.255.0.0 --gateway=10.5.0.1 --nettagadd="DNS=10.5.0.1"

echo "--- Create nodes"
for n in $(jq -r ".nodes | keys[]" $SITE) ; do
  serial=$(jq -r ".nodes.${n}.serial" $SITE)
  mac=$(jq -r ".nodes.${n}.mac" $SITE)
  i=$((i+1))
  wwctl node delete --yes ${n} || true
  wwctl node add ${n} --profile=nodes 
  wwctl node set --yes ${n} \
    --tagadd="Serial=${serial: -8}" \
    --hwaddr=${mac} \
    --ipaddr=10.5.1.${i}
done

echo "--- Import overlays"
for I in *.ww ; do
  wwctl overlay import --overwrite host $I /var/lib/tftpboot/
done

echo "---Reconfigure warewulf and build overlays"
wwctl configure --all
wwctl overlay build
