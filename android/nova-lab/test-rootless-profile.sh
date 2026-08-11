#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "$0")" && pwd)"
supervisor="$root_dir/rootless/nova-rootless-proot-supervisor.sh"
transport="$root_dir/rootless/nova-rootless-transport-probe.sh"
termux_launcher="$root_dir/rootless/nova-rootless-termux-x11.sh"
termux_properties="$root_dir/rootless/termux.properties"
profile="$root_dir/rootless/nova-rootless-profile.tsv"

[[ -x "$supervisor" ]]
[[ -x "$transport" ]]
[[ -x "$termux_launcher" ]]
[[ -f "$termux_properties" ]]
[[ -f "$profile" ]]

bash -n "$supervisor"
bash -n "$transport"
bash -n "$termux_launcher"

grep -Fqx $'profile_version\t1' "$profile"
grep -Fqx $'rootless_required\t1' "$profile"
grep -Fqx $'auth_secret_policy\tnever-export-or-back-up' "$profile"
grep -Fqx $'proton_required_runtime_appid\t4185400' "$profile"
grep -Fq -- '-b "$APP_HOME:/home/nova" \' "$supervisor"
grep -Fq -- '-b "$STEAM_CLIENT:/opt/nova-steam" \' "$supervisor"
grep -Fq 'rooted_runtime_socket_not_rootless' "$transport"
grep -Fqx 'allow-external-apps=true' "$termux_properties"

if grep -nE '(^|[[:space:]])(su|chroot|mount)([[:space:]]|$)' "$supervisor"; then
    echo "rootless supervisor contains a privileged escape hatch" >&2
    exit 1
fi

echo "rootless_profile_static=pass"
