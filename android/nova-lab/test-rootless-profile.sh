#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "$0")" && pwd)"
supervisor="$root_dir/rootless/nova-rootless-proot-supervisor.sh"
transport="$root_dir/rootless/nova-rootless-transport-probe.sh"
profile="$root_dir/rootless/nova-rootless-profile.tsv"

[[ -x "$supervisor" ]]
[[ -x "$transport" ]]
[[ -f "$profile" ]]

bash -n "$supervisor"
bash -n "$transport"

grep -Fqx $'profile_version\t1' "$profile"
grep -Fqx $'rootless_required\t1' "$profile"
grep -Fqx $'auth_secret_policy\tnever-export-or-back-up' "$profile"
grep -Fqx $'proton_required_runtime_appid\t4185400' "$profile"

if grep -nE '(^|[[:space:]])(su|chroot|mount)([[:space:]]|$)' "$supervisor"; then
    echo "rootless supervisor contains a privileged escape hatch" >&2
    exit 1
fi

echo "rootless_profile_static=pass"
