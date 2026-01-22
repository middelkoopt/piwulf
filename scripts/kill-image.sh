#!/bin/bash
set -e

: ${SESSION:=qemu}

if tmux has-session -t ${SESSION} ; then
    tmux kill-session -t ${SESSION}
fi
