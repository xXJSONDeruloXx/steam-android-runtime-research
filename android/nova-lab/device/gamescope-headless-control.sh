#!/bin/sh

set -u

# This is a disposable-rootfs control. The binary is staged beside the
# KGSL-Turnip driver by deploy-gamescope-headless-test.sh.
export GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts

exec /opt/nova-kgsl-driver/gamescope-headless \
    --backend headless \
    --output-width 64 \
    --output-height 64 \
    --nested-width 64 \
    --nested-height 64 \
    -- /usr/bin/true
