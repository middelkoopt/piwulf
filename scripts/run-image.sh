#!/bin/bash
set -e

: ${IMAGE_RAM:=2}
: ${IMAGE_CPUS:=1}
: ${SESSION:=qemu}
: ${TMP:=./tmp}

while (( $# )); do
  case $1 in
    --ram=*) RAM=${1#*=}; shift;;
    --cpus=*) CPUS=${1#*=}; shift;;
    --session=*) SESSION=${1#*=}; shift;;
    *) break ;;
  esac
done

IMAGE_NAME=${1:-head}

echo "=== run-image.sh ${SESSION} IMAGE_NAME=${IMAGE_NAME} IMAGE_RAM=${IMAGE_RAM} IMAGE_CPUS=${IMAGE_CPUS}"

: ${OS:=$(uname -s)}
: ${ARCH:=$(uname -m)}

QEMU_ACCEL="-accel kvm"
QEMU_NETDEV="dgram,remote.type=inet,remote.host=239.255.5.1,remote.port=8001"

case "${OS}-${ARCH}" in
    Linux-aarch64)
        QEMU="qemu-system-aarch64 -machine virt -cpu host"
        QEMU_EFI="/usr/share/qemu-efi-aarch64/QEMU_EFI.fd"
        ;;
    Linux-x86_64)
        QEMU="qemu-system-x86_64 -machine q35 -cpu host"
        QEMU_EFI="/usr/share/qemu/OVMF.fd"
        ;;
    Darwin-arm64)
        QEMU="qemu-system-aarch64 -machine virt -cpu host"
        QEMU_EFI="/opt/homebrew/Cellar/qemu/*/share/qemu/edk2-aarch64-code.fd"
        QEMU_ACCEL="-accel hvf"
        ;;
esac

## Create a new tmux session if it doesn't exist
if ! tmux has-session -t ${SESSION} ; then
    echo "--- create new tmux session ${SESSION}"
    tmux new-session -s ${SESSION} -d
    tmux set-option -g remain-on-exit failed 
    tmux set-option -g remain-on-exit-format ""
fi

## Start VDE if avilable and not running
if [[ $(command -v vde_switchX) ]]; then
    if ! tmux has-session -t ${SESSION}:100 ; then
        tmux new-window -k -t ${SESSION}:100 -n vde vde_switch -s ${TMP}/vde.ctl
    fi
    QEMU_NETDEV="vde,sock=${TMP}/vde.ctl"
fi

if [[ $IMAGE_NAME = "head" ]] ; then
    echo "--- start ${IMAGE_NAME} on ${SESSION}:0"
    : ${RUN:=tmux new-window -k -t ${SESSION}:0 -n ${IMAGE_NAME}}
    $RUN $QEMU $QEMU_ACCEL -m ${IMAGE_RAM}G -smp ${IMAGE_CPUS} \
        -bios $QEMU_EFI \
        -drive if=virtio,file=${TMP}/warewulf-image.img,format=raw \
        -nic user,model=virtio-net-pci,mac=52:54:00:00:02:0f,hostfwd=tcp::8022-:22,ipv6-net=fd00:2::/64 \
        -device virtio-net-pci,netdev=net1,mac=52:54:00:05:00:01 \
        -netdev ${QEMU_NETDEV},id=net1 \
        -device virtio-rng-pci \
        -serial mon:stdio -echr 0x05 \
        -nographic
else
    ## Create a new backing disk (overwrites existing disk)
    echo "--- create new disk image ${TMP}/${IMAGE_NAME}.qcow2"
    qemu-img create -f qcow2 ${TMP}/${IMAGE_NAME}.qcow2 10G

    ## Start QEMU
    printf -v IMAGE_ID "%02x" ${IMAGE_NAME//[^0-9]}
    echo "--- start ${IMAGE_NAME} on ${SESSION}:${IMAGE_ID}"
    : ${RUN:=tmux new-window -k -t ${SESSION}:${IMAGE_ID} -n ${IMAGE_NAME}}

    $RUN $QEMU $QEMU_ACCEL -m ${IMAGE_RAM}G -smp ${IMAGE_CPUS} \
        -bios $QEMU_EFI \
        -drive if=virtio,file=${TMP}/${IMAGE_NAME}.qcow2,format=qcow2 \
        -device virtio-net-pci,netdev=net0,mac=52:54:00:05:01:${IMAGE_ID} \
        -netdev ${QEMU_NETDEV},id=net0 \
        -fw_cfg name=opt/org.tianocore/IPv4PXESupport,string=y \
        -fw_cfg name=opt/org.tianocore/IPv6PXESupport,string=y \
        -device virtio-rng-pci \
        -serial mon:stdio -echr 0x05 \
        -nographic

    if [ "$(tmux list-clients -t ${SESSION})" == "" ] ; then
        echo "--- attaching to tmux session"
        exec tmux attach -t ${SESSION}:${IMAGE_NAME//[^0-9]}
    fi
fi
