#!/bin/bash
set -e

echo "### make-image.sh"
./scripts/build-containers.sh rocky10 warewulf tools
./scripts/iso-tar.sh
./scripts/container-run.sh ./scripts/iso-build.sh
pigz -f -1 -k ./tmp/warewulf-image.img
