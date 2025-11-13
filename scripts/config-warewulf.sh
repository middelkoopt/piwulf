#!/bin/bash

echo "=== config-warewulf.sh"

yq -i '
    .dhcp.["range6 start"] = "fd00:10:5::1:1" |
    .dhcp.["range6 end"] = "fd00:10:5::1:FFFE"' \
    /etc/warewulf/warewulf.conf
