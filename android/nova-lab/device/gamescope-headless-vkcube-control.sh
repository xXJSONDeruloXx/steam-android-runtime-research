#!/bin/sh

set -u

export GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts
export VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64
export VK_LOADER_DEBUG=error

exec /opt/nova-kgsl-driver/gamescope-headless \
    --backend headless \
    --output-width 64 \
    --output-height 64 \
    --nested-width 64 \
    --nested-height 64 \
    -- /usr/bin/timeout 5 /usr/bin/vkcube --wsi wayland
