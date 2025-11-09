#!/bin/bash
set -e

echo "=== setup-head.sh"

## Set hostname - container leaves empty and with mode=600
hostnamectl set-hostname warewulf
