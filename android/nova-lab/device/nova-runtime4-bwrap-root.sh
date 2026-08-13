#!/usr/bin/env sh

set -eu

real_bwrap="${STEAM_ARM64_REAL_BWRAP:?STEAM_ARM64_REAL_BWRAP is required}"

exec /usr/bin/python3 \
    /opt/nova-kgsl-driver/nova-runtime4-bwrap-proxy-client.py \
    "$real_bwrap" "$@"
