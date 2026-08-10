#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HELPER="$SCRIPT_DIR/device/nova-steamos-update-compat.sh"
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nova-steamos-update-test.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

run_case() {
    name=$1
    expected_status=$2
    shift 2
    output_file="$TEST_DIR/$name.out"
    error_file="$TEST_DIR/$name.err"
    set +e
    NOVA_STEAMOS_UPDATE_LOG="$TEST_DIR/$name.log" \
        "$HELPER" "$@" >"$output_file" 2>"$error_file"
    actual_status=$?
    set -e
    [ "$actual_status" -eq "$expected_status" ] || {
        echo "$name: expected status $expected_status, got $actual_status" >&2
        return 1
    }
    grep -q "nova_steamos_update_status=$expected_status" "$TEST_DIR/$name.log"
}

run_case capability 0 --supports-duplicate-detection
run_case check 7 check
run_case duplicate-check 7 --enable-duplicate-detection check
run_case apply 7
run_case duplicate-apply 7 --enable-duplicate-detection
run_case legacy-options 7 -d --beta check
run_case unknown-option 1 --not-a-steamos-update-option

echo 'nova_steamos_update_compat_tests=pass'
