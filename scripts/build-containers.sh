#!/bin/bash
set -e

: ${CONTAINERS:=${*:-rocky10 warewulf tools debian13}}
: ${PODMAN:=podman}

echo "=== build-containers.sh $CONTAINERS"
for IMAGE in $CONTAINERS ; do
    echo "--- Building image: ${IMAGE}"
    $PODMAN build --progress=plain -t ${IMAGE} containers/${IMAGE}
done
