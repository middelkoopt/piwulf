# Piwulf

This project is for deploying a Raspberry Pi cluster with Warewulf.

**WARNING: This image may erase any machine plugged into the same Ethernet network as the Raspbery Pi.**

*This repo is executable documentation.  It is not meant for production.*

The bootstrap image is strictly not necessary and can be accomplished by
manually configuring the Warewulf node (head) manually based on the Warewulf
container.  All the interesting bits for provisioning a Raspberry Pi are in the
Warewulf container script files and could be run on any machine.

The interesting bits are in `./containers/warewulf/*.sh`

Configure an image
* Add network configuration by placing *.nmconnection files for the node in `./containers/rocky10`.  The internal network should be statically configured.
* Describe your nodes with `./containers/warewulf/site.json`
* Set root ssh key in `./containers/rocky10/authorized_keys`
* Set admin key in `./containers/rocky10/authorized_keys`
* Run `./scripts/make-defaults.sh` to generate some defaults. See script file and examples for details.

Build the image (podman or docker required), gzip optional
```bash
./scripts/build-containers.sh 
./scripts/image-tar.sh 
./scripts/container-run.sh ./scripts/image-build.sh
pigz -f -1 -k ./tmp/warewulf-image.img
```

Note `./scripts/container-run.sh` has prepackaged utilities for
`image-build.sh`, notably you need a version of `mkfs.ext4` that supports `-d`.
You can run just `/scripts/image-build.sh` if you have the proper dependencies
installed.

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

Boot a node with an SD and enjoy (it will **erase** the sd on provision)
