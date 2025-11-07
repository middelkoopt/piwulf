#!/bin/bash
set -e

: ${PODMAN:=podman}

echo "### run-tools.sh ${PODMAN}"
exec $PODMAN run -it --rm -v .:/data tools:latest $*
