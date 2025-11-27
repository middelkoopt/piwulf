#!/bin/bash
set -e

echo "=== import-overlays.sh"

sudo wwctl --force=true overlay delete host
for I in ./containers/warewulf/*.ww ; do
  sudo wwctl overlay import --overwrite host $I /var/lib/tftpboot/
done

sudo wwctl configure dhcp
sudo wwctl configure --all
