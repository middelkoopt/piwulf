#!/bin/bash
set -e

: ${PODMAN:=podman}
: ${TMP:=./tmp}
: ${EFI:=boot/efi}

echo "=== image-build.sh"

## Disk
# partition table/offset 1 MiB
: ${BOOT_SIZE:=250} # MiB
: ${ROOT_SIZE:=2} # GiB
# partition end/alignment 1 MiB
SIZE=$(( 1 + BOOT_SIZE + ROOT_SIZE*1024 + 1 )) # MiB
DISK="${TMP}/warewulf-image.img"

echo "--- create image ${SIZE} MiB"
dd if=/dev/zero of=${DISK} bs=1M count=$((SIZE)) conv=sparse

## EFI is at offset 1M (2048*512)
PART="${DISK}@@1M"
sfdisk ${DISK} <<EOF
label: gpt
unit: sectors
first-lba: 2048
size=$((BOOT_SIZE))MiB type=uefi, name=bootfs
size=$((ROOT_SIZE))GiB type=linux, name=rootfs
EOF

echo "--- compute size and offsets (sectors)"
BOOT_PART_OFFSET=$(sfdisk --json ${DISK} | jq -r '.partitiontable.partitions[0].start') # sectors
BOOT_PART_SIZE=$(sfdisk --json ${DISK} | jq -r '.partitiontable.partitions[0].size') # sectors
ROOT_PART_OFFSET=$(sfdisk --json ${DISK} | jq -r '.partitiontable.partitions[1].start') # sectors
ROOT_PART_SIZE=$(sfdisk --json ${DISK} | jq -r '.partitiontable.partitions[1].size') # sectors
echo "$BOOT_PART_SIZE $(((BOOT_SIZE)*1024*2)) $(((1+BOOT_SIZE)*1024*2)) $ROOT_PART_OFFSET $((ROOT_SIZE*1024*1024*2)) $ROOT_PART_SIZE"

echo "--- extract boot files"
rm -rf ${TMP}/bootfs
mkdir -v ${TMP}/bootfs
tar -xf ${TMP}/warewulf-image.tar -C ${TMP}/bootfs ${EFI}

echo "--- copy boot files"
mformat -i ${PART} -T ${BOOT_PART_SIZE} ::
mcopy -i ${PART} -s ${TMP}/bootfs/${EFI}/* ::/
#mdir -i ${PART} ::/

echo "--- create root image"
tar --delete -f ${TMP}/warewulf-image.tar "${EFI}/"
mkfs.ext4 -v -E offset=$((ROOT_PART_OFFSET*512)) -L warewulf-rootfs ${DISK} -d ${TMP}/warewulf-image.tar $((ROOT_PART_SIZE/2))k

echo "--- cleanup"
rm -f ${TMP}/warewulf-image.tar
rm -rf ${TMP}/bootfs

echo "--- done"
echo "mdir -i ${PART} ::/"
echo "sudo mount -o loop,offset=$((BOOT_PART_OFFSET*512)) ${DISK} /mnt"
echo "sudo mount -o loop,offset=$((ROOT_PART_OFFSET*512)) ${DISK} /mnt"
