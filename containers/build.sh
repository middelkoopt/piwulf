#!/bin/bash
set -e

: ${PODMAN:=podman}
: ${IMAGE:=$(basename $PWD)}

$PODMAN build --progress=plain -t ${IMAGE} . $*
