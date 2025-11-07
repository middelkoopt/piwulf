#!/bin/bash
set -e

: ${PODMAN:=podman}
: ${TMP:=./tmp}

echo "=== image-tar.sh ${TMP}"

install -d --mode=0755 ${TMP}

echo "--- create container"
$PODMAN create --replace --name=warewulf-image warewulf:latest

echo "--- export image"
$PODMAN export warewulf-image > $TMP/warewulf-image.tar

echo "--- cleanup"
$PODMAN rm -v warewulf-image
