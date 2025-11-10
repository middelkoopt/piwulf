# Developer Notes

*This may be wrong or out of date. No serviceable parts inside.*

## Remove all nodes, profiles, and images.
```bash
 wwctl node delete --yes $(wwctl node list --json | jq -r '. | keys[]')
 wwctl profile delete --yes nodes
 wwctl image delete --yes nodeimage
 ```
 
 ## Boot to tmpfs
 Raspberry Pi does not support mpol option
 ```bash
 wwctl profile set nodes --root tmpfs
 sed -i 's/-o mpol=interleave //' $(wwctl image show nodeimage)/usr/lib/dracut/modules.d/90wwinit/load-wwinit.sh
 wwctl image exec --build=false nodeimage -- /usr/bin/dracut -f /boot/efi/initramfs8
 chmod 644 $(wwctl image show nodeimage)/boot/efi/initramfs8
 ```

## Import Overlays
```bash
for I in ./containers/warewulf/*.ww ; do
  sudo wwctl overlay import --overwrite host $I /var/lib/tftpboot/
done
sudo wwctl configure --all
```

## Debian 13 nodes
```bash
( cd ./containers/debian13 && ../build.sh )

podman save debian13:latest > ./tmp/debian13.tar
sudo wwctl image import --force ./tmp/debian13.tar debian13

sudo wwctl profile set --yes nodes --image debian13
sudo wwctl profile set --yes nodes --tagadd "Firmware=firmware"

sudo wwctl configure --all
sudo wwctl image build debian13
sudo wwctl overlay build
```

 ## Development
 ToDo:
 * Make Rocky10 a node image and move the following to the warewulf container
   * Move end*.nmconnection
   * Move *.mount
   * Move config.txt and cmdline.txt
   * possibly remove authorized_key
