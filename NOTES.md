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

## Development
ToDo:
 *
