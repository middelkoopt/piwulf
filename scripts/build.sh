#!/bin/bash
set -e

PI_REGISTRY=localhost:5000 # set to 'localhost' for unsecured registry
PI_IMAGE=$(basename $PWD)

podman build --progress=plain -t ${PI_IMAGE} . $*
podman tag ${PI_IMAGE} ${PI_REGISTRY}/${PI_IMAGE}
podman push ${PI_REGISTRY}/${PI_IMAGE}
