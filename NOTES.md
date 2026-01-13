# Developer Notes

*This may be wrong or out of date. No serviceable parts inside.*

## Remove all nodes, profiles, and images.
```bash
 wwctl node delete --yes $(wwctl node list --json | jq -r '. | keys[]')
 wwctl profile delete --yes nodes
 wwctl image delete --yes nodeimage
 ```
 
 ## QEMU dependencies

```bash
dnf install -y qemu-system
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

## Provision to disk

```bash
wwctl profile set --yes nodes \
  --diskname=/dev/mmcblk0 --diskwipe \
  --partname=EFI --partcreate --partnumber=1 --partsize=250M \
  --parttype=C12A7328-F81F-11D2-BA4B-00A0C93EC93B \
  --fsname=EFI --fswipe --fsformat=vfat --fspath=/boot/efi
wwctl profile set --yes nodes \
  --diskname=/dev/mmcblk0 --diskwipe \
  --partname=rootfs --partcreate --partnumber=2 \
  --fsname=rootfs --fswipe --fsformat=ext4 --fspath=/
wwctl profile set --yes nodes --root=/dev/disk/by-partlabel/rootfs
```

## UEFI Booting

Push to registry from build host
```bash
REGISTRY=pilab:5000
podman tag rocky10 ${REGISTRY}/rocky10
podman push ${REGISTRY}/rocky10
```

Setup Registry and configure node
```bash
REGISTRY=pilab:5000
install -dvp ~/.config/containers/
cat > ~/.config/containers/registries.conf <<EOF
[[registry]]
location = "${REGISTRY}"
insecure = true
EOF

./setup-head.sh

REGISTRY=pilab:5000
wwctl image import docker://${REGISTRY}/rocky10:latest rocky10
wwctl image build rocky10
./setup-nodes.sh
wwctl profile set --yes nodes --image rocky10 --tagadd IPXEMenuEntry=dracut
wwctl configure --all
wwctl overlay build
```

## Ignition

```yaml
        - ignition.firstboot
        - ignition.config.url=http://192.168.23.103/ignition.json
        - ignition.platform.id=metal
```
