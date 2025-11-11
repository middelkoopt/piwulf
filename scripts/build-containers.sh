#!/bin/bash
set -e

: ${PODMAN:=podman}

# Customize image user with `./build-containers.sh --build-arg "USER=${USER}"`

echo "=== build-containers.sh"
for IMAGE in rocky10 warewulf tools debian13 ; do
    echo "--- Building image: ${IMAGE}"
    $PODMAN build --progress=plain -t ${IMAGE} containers/${IMAGE} $*
done
