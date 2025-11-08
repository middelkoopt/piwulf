#!/bin/bash
set -e
shopt -s nullglob

echo "=== ./make-defaults.sh ==="

echo "--- Generating SSH keys for container images"
for IMAGE in rocky10 warewulf ; do
    if [[ ! -f ./containers/${IMAGE}/authorized_keys ]] ; then
        ssh-keygen -f ./containers/${IMAGE}/id_rsa -N "" -C "piwulf ${IMAGE} key"
        cp -v ./containers/${IMAGE}/id_rsa.pub ./containers/${IMAGE}/authorized_keys
    fi
done

echo "--- Copy site.json template"
if [[ ! -f ./containers/warewulf/site.json ]] ; then
    cp -v ./containers/examples/site.json ./containers/warewulf/site.json
fi

echo "--- Copy networking examples"
EXAMPLES=(./containers/rocky10/*.nmconnection)
if [[ ${#EXAMPLES[@]} == 0 ]] ; then
    cp -v ./examples/*.nmconnection ./containers/rocky10
fi
