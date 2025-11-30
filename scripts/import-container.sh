#!/bin/bash
set -e

: ${IMAGE:=${1:-rocky10}}
: ${PROFILE:=${2:-nodes}}

echo "=== import-container.sh ${IMAGE} ${PROFILE}"

echo "--- save container"
podman save ${IMAGE}:latest > ./tmp/${IMAGE}.tar

echo "--- import image"
sudo wwctl image import --force ./tmp/${IMAGE}.tar ${IMAGE}

echo "--- configure profile ${PROFILE}"
sudo wwctl profile add ${PROFILE} --profile default || true
sudo wwctl profile set --yes ${PROFILE} --image ${IMAGE}
FIRMWARE=$(podman inspect ${IMAGE}:latest --format '{{ index .Config.Labels "firmware" }}' || echo "efi")
sudo wwctl profile set --yes ${PROFILE} --tagadd "Firmware=${FIRMWARE}"

echo "--- build image"
sudo wwctl image build ${IMAGE}
