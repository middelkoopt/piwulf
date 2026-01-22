# Piwulf

This project is for deploying a Raspberry Pi cluster with Warewulf.

**WARNING: This image may erase any machine plugged into the same Ethernet network as the Raspbery Pi.**

*This repo is executable documentation.  It is not meant for production.*

The bootstrap image is strictly not necessary and can be accomplished by
manually configuring the Warewulf node (head) manually based on the Warewulf
container.  All the interesting bits for provisioning a Raspberry Pi are in the
Warewulf container script files and could be run on any machine.

The interesting bits are in `./containers/rocky10` and `./containers/warewulf`
Lots of tools in `./scripts` for leveraging containers.

Configure an image
* Add network configuration by placing `*.nmconnection` files for the node in `./containers/warewulf`.  The internal network should be statically configured.
* Describe your nodes with `./containers/warewulf/site.json`
* Set admin key in `./containers/warewulf/authorized_keys`
* Run `./scripts/make-defaults.sh` to generate some defaults. See script file and examples for details.

Build dependencies (EL)
```bash
dnf install -y podman pigz
```

Build dependencies (deb)
```bash
apt-get install --yes podman pigz
```

Build the image (podman or docker required)
```bash
./scripts/make-iso.sh
```

Write `./tmp/warewulf-image.img` to a sd card and boot a Pi. **WARNING: this erases `/dev/mmcblk0`, which might be your OS!**
```bash
blkdiscard -f /dev/mmcblk0
zcat warewulf-image.img.gz | dd of=/dev/mmcblk0 bs=1M status=progress
```

Login to the admin and run:
```bash
sudo ./setup-head.sh
sudo ./setup-image.sh
sudo ./setup-nodes.sh
```

Prep nodes and configure them to netboot via `rpi-eeprom-config --edit`
```conf
[all]
BOOT_UART=1
BOOT_ORDER=0xf412
```

Boot a node with an SD and enjoy.  **Warning:** it will **erase** the SD on provision!

Unlike for iPXE, where the config files are generated dynamically, for the pi they are in a a host overlay.  When a node or image is added, or a node updated (kernel ops) the following must be run to rebuild `/var/lib/tftpboot/config.txt` and friends:

```bash
sudo wwctl configure dhcp
```

## Running on a Mac

install podman with lima via
```bash
brew install lima podman qemu vde tmux
limactl create --yes --mount-writable template:podman
limactl start podman
```
Follow the displayed instructions (copy-paste) to link the vm and host (podman socket)
```bash
podman system connection add lima-podman "unix://${HOME}/.lima/podman/sock/podman.sock"
podman system connection default lima-podman
```
