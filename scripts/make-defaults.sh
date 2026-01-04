#!/bin/bash
set -e

: ${TEMPLATE:=${1:-qemu}}

echo "=== ./make-defaults.sh ${TEMPLATE}"

for IMAGE in warewulf ; do
    if [[ ! -f ./containers/${IMAGE}/authorized_keys ]] ; then
        echo "--- Generating SSH keys for ${IMAGE} container"
        ssh-keygen -f ./containers/${IMAGE}/id_rsa -N "" -C "piwulf ${IMAGE} key"
        cp -v ./containers/${IMAGE}/id_rsa.pub ./containers/${IMAGE}/authorized_keys
    fi
done

echo "--- Copy site.json template"
cp -v ./examples/${TEMPLATE}/site.json ./containers/warewulf/site.json

echo "--- Copy networking examples"
rm -v ./containers/warewulf/*.nmconnection
cp -v ./examples/${TEMPLATE}/*.nmconnection ./containers/warewulf
