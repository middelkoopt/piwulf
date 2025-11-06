#!/bin/bash
set -e

for IMAGE in rocky10 warewulf ; do
    podman build --progress=plain -t ${IMAGE} --build-arg "USER=${USER}" containers/${IMAGE} $*
done
