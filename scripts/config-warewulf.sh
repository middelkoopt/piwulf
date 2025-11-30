#!/bin/bash

echo "=== config-warewulf.sh"

yq -i '.ipaddr6 = "fd00:10:5::1/64"' /etc/warewulf/warewulf.conf
