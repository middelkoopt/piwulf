#!/bin/bash
set -e

echo "=== setup-head.sh"

## Set hostname - container leaves empty with mode=600
hostnamectl set-hostname warewulf

## Expand filesystem
rootfs-expand
