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

## Development
Build
```bash
WW_VERSION=v4.6.4
git clone --no-checkout https://github.com/warewulf/warewulf.git && \
cd warewulf
git checkout -B ${WW_VERSION} refs/tags/${WW4_VERSION}
make config \
  PREFIX=/usr \
  SYSCONFDIR=/etc \
  LOCALSTATEDIR=/var/lib \
  SHAREDSTATEDIR=/var/lib \
  TFTPDIR=/var/lib/tftpboot
make all
make build 
sudo make install
wwctl completion bash > /etc/bash_completion.d/wwctl
```

## IPv6

The Pi4 will boot off of IPv6, the Pi5 has issues.
* Set USE_IPV6=1 in the EEPROM
* Remove the IPv4 DHCP range IP address and do not set dhcp template to static

ToDo:
 * Cleanup
   * Make Ipaddr and Ipaddr6 use the prefix length and then add a "Ip and IP6" to get just the ip?

## UEFI Booting
