#!/bin/bash
set -e
shopt -s nullglob

: ${TEMPLATE:=${1:-qemu}}

echo "=== ./make-defaults.sh ${TEMPLATE}"

for IMAGE in warewulf ; do
    if [[ ! -f ./containers/${IMAGE}/authorized_keys ]] ; then
        echo "--- Generating SSH keys for ${IMAGE} container"
        ssh-keygen -f ./containers/${IMAGE}/id_rsa -N "" -C "piwulf ${IMAGE} key"
        cp -v ./containers/${IMAGE}/id_rsa.pub ./containers/${IMAGE}/authorized_keys
    fi
done

if [[ ! -f ./containers/warewulf/site.json ]] ; then
    echo "--- Copy site.json template"
    cp -v ./examples/${TEMPLATE}/site.json ./containers/warewulf/site.json
fi

EXAMPLES=(./containers/warewulf/*.nmconnection)
if [[ ${#EXAMPLES[@]} == 0 ]] ; then
    echo "--- Copy networking examples"
    cp -v ./examples/${TEMPLATE}/*.nmconnection ./containers/warewulf
fi
