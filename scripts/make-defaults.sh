#!/bin/bash
set -e

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
    cp -v ./containers/warewulf/site.json.template ./containers/warewulf/site.json
fi
