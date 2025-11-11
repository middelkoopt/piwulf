#!/bin/bash
set -e

echo "### make-image.sh"
./scripts/build-containers.sh
./scripts/image-tar.sh
./scripts/container-run.sh ./scripts/image-build.sh
pigz -f -1 -k ./tmp/warewulf-image.img
