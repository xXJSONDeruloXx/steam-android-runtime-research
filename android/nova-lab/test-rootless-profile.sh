#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "$0")" && pwd)"
supervisor="$root_dir/rootless/nova-rootless-proot-supervisor.sh"
transport="$root_dir/rootless/nova-rootless-transport-probe.sh"
termux_launcher="$root_dir/rootless/nova-rootless-termux-x11.sh"
proc_net_shadow="$root_dir/rootless/nova-rootless-proc-net-shadow.sh"
pulseaudio_helper="$root_dir/rootless/nova-rootless-pulseaudio-tcp.sh"
session_guard="$root_dir/rootless/nova-rootless-session-guard.py"
runtime4_helper="$root_dir/rootless/nova-rootless-prepare-runtime4.sh"
runtime4_vdf="$root_dir/rootless/nova-rootless-steam-arm64-compatibilitytools.vdf.in"
guest_rootfs_helper="$root_dir/rootless/nova-rootless-prepare-guest-rootfs.sh"
rootfs_archive_helper="$root_dir/rootless/nova-rootless-extract-rootfs.sh"
bsdtar_bootstrap_builder="$root_dir/build-bsdtar-bootstrap.sh"
steamui_holo_packages="$root_dir/rootless/nova-rootless-steamui-holo-packages.tsv"
steamui_external_assets="$root_dir/rootless/nova-rootless-steamui-external-assets.tsv"
termux_properties="$root_dir/rootless/termux.properties"
profile="$root_dir/rootless/nova-rootless-profile.tsv"
manifest="$root_dir/AndroidManifest.xml"
bridge="$root_dir/src/main/java/com/xjsonderulo/steamandroid/novalab/RootlessTermuxBridge.java"

[[ -x "$supervisor" ]]
[[ -x "$transport" ]]
[[ -x "$termux_launcher" ]]
[[ -x "$proc_net_shadow" ]]
[[ -x "$pulseaudio_helper" ]]
[[ -f "$session_guard" ]]
[[ -x "$runtime4_helper" ]]
[[ -f "$runtime4_vdf" ]]
[[ -x "$guest_rootfs_helper" ]]
[[ -x "$rootfs_archive_helper" ]]
[[ -x "$bsdtar_bootstrap_builder" ]]
[[ -f "$steamui_holo_packages" ]]
[[ -f "$steamui_external_assets" ]]
[[ -f "$termux_properties" ]]
[[ -f "$profile" ]]
[[ -f "$manifest" ]]
[[ -f "$bridge" ]]

bash -n "$supervisor"
bash -n "$transport"
bash -n "$termux_launcher"
bash -n "$proc_net_shadow"
bash -n "$pulseaudio_helper"
bash -n "$runtime4_helper"
bash -n "$guest_rootfs_helper"
bash -n "$rootfs_archive_helper"
python3 -m py_compile "$session_guard"

grep -Fqx $'profile_version\t2' "$profile"
grep -Fqx $'rootless_required\t1' "$profile"
grep -Fqx $'auth_secret_policy\tnever-export-or-back-up' "$profile"
grep -Fqx $'proton_required_runtime_appid\t4185400' "$profile"
grep -Fqx $'steam_seed_package\tbins_linuxarm64_linuxarm64.zip.0f238017c65e844f71581d1fae8fb42f410e1032' "$profile"
grep -Fqx $'steam_seed_sha256\t1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82' "$profile"
grep -Fqx $'rootfs_archive\tsystem.rootfs.zst' "$profile"
grep -Fqx $'rootfs_archive_size\t384971555' "$profile"
grep -Fqx $'rootfs_archive_sha256\t7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf' "$profile"
steamui_holo_count=$(awk -F '\t' '$1 !~ /^#/ && NF >= 5 { count++ } END { print count + 0 }' "$steamui_holo_packages")
[[ "$steamui_holo_count" == 161 ]]
steamui_holo_sha=$(shasum -a 256 "$steamui_holo_packages" | awk '{ print $1 }')
grep -Fqx $'steamui_holo_package_closure_sha256\t'"$steamui_holo_sha" "$profile"
grep -Fqx $'steamui_holo_package_closure_count\t161' "$profile"
external_asset_count=$(awk -F '\t' '$1 !~ /^#/ && NF >= 5 { count++ } END { print count + 0 }' "$steamui_external_assets")
[[ "$external_asset_count" == 2 ]]
grep -Fq -- '-b "$APP_HOME:/home/nova" \' "$supervisor"
grep -Fq -- '-b "$STEAM_CLIENT:/opt/nova-steam" \' "$supervisor"
grep -Fq -- '-b /proc:/proc \' "$supervisor"
grep -Fq -- '-b /dev:/dev \' "$supervisor"
grep -Fq -- 'unexpected_steam_data_link' "$supervisor"
grep -Fq -- 'refusing_real_steam_data_path' "$supervisor"
grep -Fq -- '-b "$PROC_NET:/proc/net" \' "$supervisor"
grep -Fq -- 'NOVA_ROOTLESS_RUNTIME4_SHADOW' "$supervisor"
grep -Fq -- 'RESOLV_CONF' "$supervisor"
grep -Fq -- 'NOVA_ROOTLESS_RESOLV_CONF' "$supervisor"
grep -Fq -- 'NOVA_ROOTLESS_PROOT_TMP_DIR' "$supervisor"
grep -Fq -- 'TMPDIR=/tmp' "$supervisor"
grep -Fq -- '/etc/resolv.conf' "$supervisor"
grep -Fq -- 'PULSE_SERVER=' "$supervisor"
grep -Fq -- 'PATH=/usr/bin:/bin:/usr/sbin:/sbin' "$supervisor"
grep -Fq -- '--sysvipc' "$supervisor"
grep -Fq 'rooted_runtime_socket_not_rootless' "$transport"
grep -Fq 'transport=loopback-tcp' "$transport"
grep -Fq 'NOVA_ROOTLESS_TERMUX_PRESENT' "$transport"
grep -Fqx 'allow-external-apps=true' "$termux_properties"
grep -Fq 'com.termux.permission.RUN_COMMAND' "$manifest"
grep -Fq '<package android:name="com.termux" />' "$manifest"
grep -Fq '"-c", ". /dev/stdin"' "$bridge"
grep -Fq 'putExtra(EXTRA_BACKGROUND_LOG_LEVEL, 2)' "$bridge"
grep -Fq 'context.startForegroundService(intent)' "$bridge"
grep -Fq '00000000' "$proc_net_shadow"
grep -Fq 'module-native-protocol-tcp' "$pulseaudio_helper"
grep -Fq '127.0.0.1' "$pulseaudio_helper"
grep -Fqx $'session_log_cap_bytes\t67108864' "$profile"
grep -Fq 'NOISY_LOGS' "$session_guard"
grep -Fq 'SteamLinuxRuntime_4-arm64' "$runtime4_helper"
grep -Fq 'rooted_runtime_modified=0' "$guest_rootfs_helper"
grep -Fq 'steamui_patch=0' "$guest_rootfs_helper"
grep -Fq -- '--needed -U' "$guest_rootfs_helper"
grep -Fq 'export PATH=/usr/bin:/bin:/usr/sbin:/sbin' "$guest_rootfs_helper"
grep -Fq 'missing_guest_path' "$guest_rootfs_helper"
grep -Fq 'rootless_archive_extract=1' "$rootfs_archive_helper"
grep -Fq 'rooted_runtime_modified=0' "$rootfs_archive_helper"
grep -Fq 'archive_decompress' "$rootfs_archive_helper"
grep -Fq -- '-T "$file_entries"' "$rootfs_archive_helper"
grep -Fq 'archive_entries=' "$rootfs_archive_helper"
grep -Fq "s/ -> .*//" "$rootfs_archive_helper"
grep -Fq '/usr/bin/bsdtar' "$rootfs_archive_helper"
grep -Fq -- '--no-same-owner --no-same-permissions --zstd' "$rootfs_archive_helper"
grep -Fq -- '-xf /tmp/nova-rootfs-system.rootfs.zst' "$rootfs_archive_helper"
grep -Fq '"$system_mkdir" -p "$STATE/proot-tmp"' "$rootfs_archive_helper"
grep -Fq '"$system_chmod" -R u+rwX "$stage"' "$rootfs_archive_helper"
grep -Fq 'NOVA_BSDTAR_BOOTSTRAP_DIR' "$bsdtar_bootstrap_builder"
grep -Fq 'libarchive.so.13' "$bsdtar_bootstrap_builder"
grep -Fq 'libxml2.so.16' "$bsdtar_bootstrap_builder"
grep -Fq 'nova-bsdtar-bootstrap' "$root_dir/build.sh"
grep -Fq 'nova-bsdtar-bootstrap/usr/bin/bsdtar' \
    "$root_dir/src/main/java/com/xjsonderulo/steamandroid/novalab/LauncherActivity.java"
grep -Fq '"nova-rootless-extract-rootfs.sh"' \
    "$root_dir/src/main/java/com/xjsonderulo/steamandroid/novalab/LauncherActivity.java"
grep -Fq '"nova-zstd"' \
    "$root_dir/src/main/java/com/xjsonderulo/steamandroid/novalab/LauncherActivity.java"
grep -Fq 'target.getParentFile()' \
    "$root_dir/src/main/java/com/xjsonderulo/steamandroid/novalab/LauncherActivity.java"
grep -Fq 'debian-bookworm' "$steamui_external_assets"
grep -Fq 'libpipewire' "$steamui_holo_packages"
grep -Fq 'libpulse' "$steamui_holo_packages"
grep -Fq 'gdk-pixbuf2' "$steamui_holo_packages"
grep -Fq $'\tsdl3\t3.2.26-1\t' "$steamui_holo_packages"
grep -Fq $'\tffmpeg\t2:8.0-3\t' "$steamui_holo_packages"
grep -Fq 'require_tool_appid' "$runtime4_vdf"
grep -Fq '"appid"               "4628740"' "$runtime4_vdf"
grep -Fq '"depotid"             "4628741"' "$runtime4_vdf"
grep -Fq '"appid"         "4185400"' "$runtime4_vdf"
grep -Fq '"depotid"       "4185401"' "$runtime4_vdf"

if grep -nE '(^|[[:space:]])(su|chroot|mount)([[:space:]]|$)' "$supervisor"; then
    echo "rootless supervisor contains a privileged escape hatch" >&2
    exit 1
fi

echo "rootless_profile_static=pass"
