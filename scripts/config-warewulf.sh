#!/bin/bash

echo "=== config-warewulf.sh"

yq -i '
    .dhcp.["range6 start"] = "fd00:10:5::2:1" |
    .dhcp.["range6 end"] = "fd00:10:5::2:FFFF" |
    .ipaddr6 = "fd00:10:5::1/64"
    ' /etc/warewulf/warewulf.conf
