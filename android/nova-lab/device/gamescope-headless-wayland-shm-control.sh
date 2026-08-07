#!/bin/sh

set -u

export GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts

exec /opt/nova-kgsl-driver/gamescope-headless \
    --backend headless \
    --output-width 64 \
    --output-height 64 \
    --nested-width 64 \
    --nested-height 64 \
    -- /opt/nova-kgsl-driver/wayland-shm-control
