#!/bin/sh

set -u

export GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts
OUTPUT_WIDTH=${NOVA_AHB_WIDTH:-64}
OUTPUT_HEIGHT=${NOVA_AHB_HEIGHT:-64}
NOVA_AHB_TRACE=${NOVA_AHB_TRACE:-0}
NOVA_AHB_SOCKET_TRACE=${NOVA_AHB_SOCKET_TRACE:-0}
if [ -r /opt/nova-steam/ahb-trace ]; then
    NOVA_AHB_TRACE=$(cat /opt/nova-steam/ahb-trace)
fi
if [ -r /opt/nova-steam/ahb-socket-trace ]; then
    NOVA_AHB_SOCKET_TRACE=$(cat /opt/nova-steam/ahb-socket-trace)
fi
export NOVA_AHB_TRACE
export NOVA_AHB_SOCKET_TRACE
export NOVA_WAYLAND_SHM_MAX_FRAMES="${NOVA_AHB_FRAME_COUNT:-5}"
export NOVA_WAYLAND_SHM_RELEASE_GRACE_MS="${NOVA_WAYLAND_SHM_RELEASE_GRACE_MS:-1000}"

exec /opt/nova-kgsl-driver/gamescope-headless \
    --backend headless \
    --output-width "$OUTPUT_WIDTH" \
    --output-height "$OUTPUT_HEIGHT" \
    --nested-width "$OUTPUT_WIDTH" \
    --nested-height "$OUTPUT_HEIGHT" \
    -- /opt/nova-kgsl-driver/wayland-shm-control
