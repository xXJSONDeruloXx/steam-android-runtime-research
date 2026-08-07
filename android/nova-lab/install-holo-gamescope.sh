#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

HOLO_PACKAGES="${HOLO_PACKAGES:-vulkan-tools vulkan-headers vulkan-freedreno gamescope}" \
    "$SCRIPT_DIR/install-holo-packages.sh"
