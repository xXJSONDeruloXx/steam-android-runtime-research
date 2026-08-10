#!/system/bin/sh

set -eu

ACTION="${1:-}"
LEGACY_ROOT="${2:-/data/local/tmp/nova-holo-rootfs}"
TERMUX_APK="${3:-}"
APP_DIR="${4:-}"
RUNTIME_PARENT=/data/local/tmp/nova-runtimes
ACTIVE_MARKER=/data/local/tmp/nova-active-runtime
MANIFEST_ASSET="$APP_DIR/nova-runtime-manifest.tsv"
PACKAGE_MANIFEST_ASSET="$APP_DIR/holo-direct-termux-x11.packages.tsv"
PACKAGE_INSTALLER="$APP_DIR/holo-package-install.sh"
ZSTD="$APP_DIR/nova-zstd"
ZIP_REBASE="$APP_DIR/nova-zip-rebase"

if [ "$ACTION" != provision ]; then
    echo "nova_provision_error=usage" >&2
    exit 2
fi

if [ ! -r "$MANIFEST_ASSET" ] || [ ! -r "$PACKAGE_MANIFEST_ASSET" ] ||
    [ ! -x "$PACKAGE_INSTALLER" ] || [ ! -x "$ZSTD" ] || [ ! -x "$ZIP_REBASE" ]; then
    echo "nova_provision_status=fail reason=missing_provisioning_asset" >&2
    exit 1
fi
if [ -z "$TERMUX_APK" ] || [ ! -f "$TERMUX_APK" ]; then
    echo "nova_provision_status=fail reason=missing_termux_x11_apk" >&2
    exit 1
fi

manifest_value() {
    /system/bin/awk -F '\t' -v key="$1" '$1 == key { print $2; exit }' "$MANIFEST_ASSET"
}

log_file="$RUNTIME_PARENT/provisioning.log"
mkdir -p "$RUNTIME_PARENT"
log() {
    line="$1"
    echo "$line"
    echo "$line" >>"$log_file"
}

provision_progress() {
    progress="$1"
    phase="$2"
    artifact="${3:-}"
    log "nova_provision_progress=$progress phase=$phase artifact=$artifact"
}

fail() {
    log "nova_provision_status=fail reason=$1"
    exit 1
}

runtime_version=$(manifest_value runtime_version)
rootfs_base_url=$(manifest_value rootfs_base_url)
rootfs_archive=$(manifest_value rootfs_archive)
rootfs_size=$(manifest_value rootfs_size)
rootfs_sha256=$(manifest_value rootfs_sha256)
holo_package_base_url=$(manifest_value holo_package_base_url)
steam_manifest_url=$(manifest_value steam_manifest_url)
steam_manifest_size=$(manifest_value steam_manifest_size)
steam_manifest_sha256=$(manifest_value steam_manifest_sha256)
steam_seed_package=$(manifest_value steam_seed_package)
steam_seed_url=$(manifest_value steam_seed_url)
steam_seed_size=$(manifest_value steam_seed_size)
steam_seed_sha256=$(manifest_value steam_seed_sha256)
steamrt_url=$(manifest_value steamrt_url)
steamrt_size=$(manifest_value steamrt_size)
steamrt_sha256=$(manifest_value steamrt_sha256)
package_closure_sha256=$(manifest_value package_closure_sha256)
turnip_driver_name=$(manifest_value turnip_driver_name)
turnip_driver_size=$(manifest_value turnip_driver_size)
turnip_driver_sha256=$(manifest_value turnip_driver_sha256)
turnip_icd_name=$(manifest_value turnip_icd_name)
turnip_icd_sha256=$(manifest_value turnip_icd_sha256)
required_free_bytes=$(manifest_value required_free_bytes)
required_free_inodes=$(manifest_value required_free_inodes)
steam_uid=$(manifest_value steam_uid)
steam_gid=$(manifest_value steam_gid)
steam_home_uid=$(manifest_value steam_home_uid)
steam_home_gid=$(manifest_value steam_home_gid)
steam_seed_zip_prefix_bytes=$(manifest_value steam_seed_zip_prefix_bytes)

for value in runtime_version rootfs_base_url rootfs_archive rootfs_size rootfs_sha256 \
    holo_package_base_url steam_manifest_url steam_manifest_size steam_manifest_sha256 \
    steam_seed_package steam_seed_url steam_seed_size steam_seed_sha256 steamrt_url \
    steamrt_size steamrt_sha256 package_closure_sha256 turnip_driver_name turnip_driver_size turnip_driver_sha256 \
    turnip_icd_name turnip_icd_sha256 required_free_bytes required_free_inodes steam_uid \
    steam_gid steam_home_uid steam_home_gid steam_seed_zip_prefix_bytes; do
    eval "value_text=\${$value:-}"
    if [ -z "$value_text" ]; then
        fail "manifest_missing_$value"
    fi
done

if [ "$(/system/bin/id -u)" != 0 ]; then
    fail root_unavailable
fi
if [ "$(/system/bin/getprop ro.product.cpu.abilist64)" != arm64-v8a ] &&
    [ "$(/system/bin/uname -m)" != aarch64 ]; then
    fail unsupported_arm64_device
fi
if [ ! -d /data/local/tmp ] || [ ! -w /data/local/tmp ]; then
    fail runtime_path_unwritable
fi

available_kb=$(/system/bin/df -Pk /data/local/tmp | /system/bin/awk 'NR == 2 { print $4; exit }')
available_inodes=$(/system/bin/df -Pi /data/local/tmp | /system/bin/awk 'NR == 2 { print $4; exit }')
case "$available_kb:$available_inodes" in
    ''|*[!0-9:]*|*:*:*)
        fail free_space_probe
        ;;
esac
log "nova_provision_root=uid0"
required_free_kb=$(/system/bin/awk -v bytes="$required_free_bytes" \
    'BEGIN { print int(bytes / 1024) }')
log "nova_provision_free_kb=$available_kb required=$required_free_kb"
log "nova_provision_free_inodes=$available_inodes required=$required_free_inodes"
# Keep the comparison in KiB: Android's shell arithmetic is 32-bit on some
# builds, so multiplying a large free-space value by 1024 can wrap before the
# test even though df reported the correct 64-bit filesystem value.
if [ "$available_kb" -lt "$required_free_kb" ]; then
    fail insufficient_free_bytes
fi
if [ "$available_inodes" -lt "$required_free_inodes" ]; then
    fail insufficient_free_inodes
fi
provision_progress 0 preflight device

ensure_steam_runtime_sonames() {
    steam_runtime_root="$1"
    for nova_libdir in $(/system/bin/find "$steam_runtime_root" \
        -type d -path '*/files/lib/aarch64-linux-gnu' 2>/dev/null); do
        for nova_library in $(/system/bin/find "$nova_libdir" -maxdepth 1 \
            -type f -name '*.so.*.*' 2>/dev/null); do
            nova_filename=${nova_library##*/}
            nova_stem=${nova_filename%%.so.*}
            nova_version=${nova_filename#*.so.}
            nova_soname="$nova_libdir/$nova_stem.so.${nova_version%%.*}"
            if [ ! -e "$nova_soname" ] &&
                ! /system/bin/ln -s "$nova_filename" "$nova_soname"; then
                return 1
            fi
        done
    done
    return 0
}

if [ -f "$ACTIVE_MARKER" ]; then
    active_root=$(/system/bin/tr -d '\r\n' <"$ACTIVE_MARKER")
    case "$active_root" in
        "$RUNTIME_PARENT"/*/rootfs)
            active_version_dir=${active_root%/rootfs}
            active_version=${active_version_dir##*/}
            if [ "$active_version" = "$runtime_version" ] &&
                [ -f "$active_version_dir/provisioning/complete" ]; then
                ensure_steam_runtime_sonames \
                    "$active_root/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64" ||
                    fail active_runtime_soname_repair
                log "nova_provision_status=already-active root=$active_root"
                exit 0
            fi
            if [ -f "$active_version_dir/provisioning/complete" ]; then
                log "nova_provision_active_version=$active_version requested=$runtime_version"
            fi
            ;;
        '')
            ;;
        *)
            log "nova_provision_active_marker=ignored reason=outside_versioned_runtime"
            ;;
    esac
fi

runtime_dir="$RUNTIME_PARENT/$runtime_version"
stage_dir="$RUNTIME_PARENT/.$runtime_version.staging"
rootfs="$stage_dir/rootfs"
downloads="$stage_dir/downloads"
packages="$downloads/packages"
provisioning="$stage_dir/provisioning"
work="$stage_dir/work"
steam_home="$rootfs/opt/nova-steam/home"
steam_root="$steam_home/.local/share/Steam"
driver_dir="$rootfs/opt/nova-kgsl-driver"
stage_cleanup=1

cleanup_stage() {
    status=$?
    if [ "$status" -ne 0 ] && [ "$stage_cleanup" -eq 1 ] && [ -d "$stage_dir" ]; then
        /system/bin/rm -rf "$stage_dir"
        echo "nova_provision_staging_cleanup=pass path=$stage_dir" >>"$log_file"
    fi
}
trap cleanup_stage EXIT INT TERM

runtime_is_valid() {
    candidate="$1"
    [ -d "$candidate" ] || return 1
    missing=0
    for required_path in \
        "$candidate/rootfs/usr/lib/ld-linux-aarch64.so.1" \
        "$candidate/rootfs/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf" \
        "$candidate/rootfs/usr/bin/Xwayland" \
        "$candidate/rootfs/usr/bin/xkbcomp" \
        "$candidate/rootfs/usr/bin/pacman" \
        "$candidate/rootfs/opt/nova-kgsl-driver/$turnip_driver_name" \
        "$candidate/rootfs/opt/nova-kgsl-driver/$turnip_icd_name" \
        "$candidate/rootfs/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam" \
        "$candidate/rootfs/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/VERSIONS.txt"; do
        if [ ! -e "$required_path" ]; then
            log "nova_provision_validation_missing=$required_path"
            missing=1
        fi
    done
    if [ ! -f "$candidate/provisioning/complete" ]; then
        log "nova_provision_validation_missing=$candidate/provisioning/complete"
        missing=1
    fi
    [ "$missing" -eq 0 ]
}

activate_runtime() {
    candidate="$1"
    old_active=
    if [ -f "$ACTIVE_MARKER" ]; then
        old_active=$(/system/bin/tr -d '\r\n' <"$ACTIVE_MARKER")
    fi
    if [ -n "$old_active" ] && [ "$old_active" != "$candidate/rootfs" ]; then
        /system/bin/printf '%s\n' "$old_active" >"$RUNTIME_PARENT/previous-active-runtime.new.$$"
        /system/bin/mv -f "$RUNTIME_PARENT/previous-active-runtime.new.$$" \
            "$RUNTIME_PARENT/previous-active-runtime"
    fi
    /system/bin/printf '%s\n' "$candidate/rootfs" >"$ACTIVE_MARKER.new.$$"
    /system/bin/chmod 644 "$ACTIVE_MARKER.new.$$"
    /system/bin/mv -f "$ACTIVE_MARKER.new.$$" "$ACTIVE_MARKER"
    log "nova_provision_active=pass root=$candidate/rootfs"
}

if runtime_is_valid "$runtime_dir"; then
    activate_runtime "$runtime_dir"
    log "nova_provision_status=already-staged version=$runtime_version"
    exit 0
fi

/system/bin/rm -rf "$stage_dir"
/system/bin/rm -rf "$runtime_dir"
/system/bin/mkdir -p "$rootfs" "$packages" "$provisioning" "$work"
/system/bin/cp "$MANIFEST_ASSET" "$provisioning/manifest.tsv"
/system/bin/cp "$PACKAGE_MANIFEST_ASSET" "$provisioning/packages.tsv"
/system/bin/chmod 644 "$provisioning/manifest.tsv" "$provisioning/packages.tsv"
actual_package_closure_sha256=$(/system/bin/sha256sum "$PACKAGE_MANIFEST_ASSET" | /system/bin/awk '{ print $1 }')
[ "$actual_package_closure_sha256" = "$package_closure_sha256" ] ||
    fail package_closure_sha256
log "nova_provision_version=$runtime_version"
log "nova_provision_legacy_root_preserved=$LEGACY_ROOT"

download_verified() {
    url="$1"
    destination="$2"
    expected_size="$3"
    expected_sha256="$4"
    progress_start="${5:-0}"
    progress_end="${6:-$progress_start}"
    progress_phase="${7:-download}"
    progress_artifact=$(basename "$destination")
    provision_progress "$progress_start" "$progress_phase" "$progress_artifact"
    if [ -f "$destination" ]; then
        cached_size=$(/system/bin/wc -c <"$destination" | /system/bin/tr -d '[:space:]')
        cached_sha256=$(/system/bin/sha256sum "$destination" | /system/bin/awk '{ print $1 }')
        if { [ -z "$expected_size" ] || [ "$cached_size" = "$expected_size" ]; } &&
            [ "$cached_sha256" = "$expected_sha256" ]; then
            log "nova_provision_cached=$(basename "$destination") sha256=$cached_sha256"
            provision_progress "$progress_end" "$progress_phase" "$progress_artifact"
            return 0
        fi
        /system/bin/rm -f "$destination"
    fi
    partial="$destination.part"
    /system/bin/rm -f "$partial"
    log "nova_provision_download=$(basename "$destination")"
    if [ -n "$expected_size" ] && [ "$expected_size" -gt 0 ]; then
        /system/bin/curl --fail --location --retry 5 --retry-delay 2 \
            --connect-timeout 20 --silent --show-error \
            --output "$partial" "$url" &
        download_pid=$!
        while /system/bin/kill -0 "$download_pid" 2>/dev/null; do
            current_size=0
            if [ -f "$partial" ]; then
                current_size=$(/system/bin/wc -c <"$partial" 2>/dev/null |
                    /system/bin/tr -d '[:space:]')
            fi
            case "$current_size" in
                ''|*[!0-9]*) current_size=0 ;;
            esac
            size_step=$((expected_size / 100))
            if [ "$size_step" -lt 1 ]; then
                size_step=1
            fi
            artifact_percent=$((current_size / size_step))
            if [ "$artifact_percent" -gt 100 ]; then
                artifact_percent=100
            fi
            progress_span=$((progress_end - progress_start))
            progress_value=$((progress_start + artifact_percent * progress_span / 100))
            provision_progress "$progress_value" "$progress_phase" "$progress_artifact"
            /system/bin/sleep 1
        done
        if ! wait "$download_pid"; then
            /system/bin/rm -f "$partial"
            fail "download_$(basename "$destination")"
        fi
    else
        if ! /system/bin/curl --fail --location --retry 5 --retry-delay 2 \
            --connect-timeout 20 --silent --show-error \
            --output "$partial" "$url"; then
            /system/bin/rm -f "$partial"
            fail "download_$(basename "$destination")"
        fi
    fi
    actual_size=$(/system/bin/wc -c <"$partial" | /system/bin/tr -d '[:space:]')
    actual_sha256=$(/system/bin/sha256sum "$partial" | /system/bin/awk '{ print $1 }')
    if [ -n "$expected_size" ] && [ "$actual_size" != "$expected_size" ]; then
        /system/bin/rm -f "$partial"
        fail "size_mismatch_$(basename "$destination")"
    fi
    if [ "$actual_sha256" != "$expected_sha256" ]; then
        /system/bin/rm -f "$partial"
        fail "sha256_mismatch_$(basename "$destination")"
    fi
    /system/bin/mv "$partial" "$destination"
    log "nova_provision_verified=$(basename "$destination") size=$actual_size sha256=$actual_sha256"
    provision_progress "$progress_end" "$progress_phase" "$progress_artifact"
}

rootfs_file="$downloads/$rootfs_archive"
download_verified "$rootfs_base_url/$rootfs_archive" "$rootfs_file" \
    "$rootfs_size" "$rootfs_sha256" 0 30 rootfs
log "nova_provision_extract=rootfs"
if ! "$ZSTD" -q -d -c "$rootfs_file" | /system/bin/tar -x -f - -C "$rootfs"; then
    fail rootfs_extract
fi
for required_path in \
    "$rootfs/usr/bin/sh" \
    "$rootfs/usr/bin/env" \
    "$rootfs/usr/bin/pacman" \
    "$rootfs/usr/bin/xz" \
    "$rootfs/usr/lib/ld-linux-aarch64.so.1" \
    "$rootfs/usr/lib/libc.so.6"; do
    [ -e "$required_path" ] || fail "rootfs_missing_$(basename "$required_path")"
done
provision_progress 30 rootfs_extract "$rootfs_archive"

package_count=0
package_total=$(/system/bin/awk -F '\t' 'NF >= 5 && $1 !~ /^#/ { count++ } END { print count + 0 }' \
    "$PACKAGE_MANIFEST_ASSET")
[ "$package_total" -gt 0 ] || fail package_closure_empty
package_index=0
provision_progress 30 packages package_closure
while IFS="$(printf '\t')" read -r repo package_name package_version package_sha256 package_file; do
    [ -n "${repo:-}" ] || continue
    package_url="$holo_package_base_url/$repo/os/aarch64/$package_file"
    package_index=$((package_index + 1))
    package_start=$((30 + (package_index - 1) * 24 / package_total))
    package_end=$((30 + package_index * 24 / package_total))
    download_verified "$package_url" "$packages/$package_file" \
        "$(/system/bin/awk -F '\t' -v name="$package_file" '$5 == name { print $6; exit }' /dev/null)" \
        "$package_sha256" "$package_start" "$package_end" packages
    package_count=$((package_count + 1))
done <"$PACKAGE_MANIFEST_ASSET"
# The pinned closure intentionally carries hashes but not a second, drifting
# size database. Package size is checked by curl's completed download and the
# SHA-256 gate above; pacman performs the archive-format check during install.
if [ "$package_count" -ne 59 ]; then
    fail "unexpected_package_closure_count_$package_count"
fi
provision_progress 54 packages package_closure

package_log="$provisioning/package-install.log"
if ! /system/bin/sh "$PACKAGE_INSTALLER" "$rootfs" "$packages" "$package_log" \
    "$work/package-install"; then
    fail package_install
fi
/system/bin/grep -q '^install_status=0$' "$package_log" || fail package_install_report
provision_progress 56 package_install "$package_count-packages"

steam_manifest_file="$downloads/steam_client.manifest"
download_verified "$steam_manifest_url" "$steam_manifest_file" \
    "$steam_manifest_size" "$steam_manifest_sha256" 56 57 steam_manifest
if ! /system/bin/grep -q "$steam_seed_package" "$steam_manifest_file"; then
    fail steam_manifest_seed_mismatch
fi

seed_file="$downloads/$steam_seed_package"
download_verified "$steam_seed_url" "$seed_file" "$steam_seed_size" "$steam_seed_sha256" \
    57 72 steam_seed
runtime_file="$downloads/steam-runtime-steamrt-arm64.tar.xz"
download_verified "$steamrt_url" "$runtime_file" "$steamrt_size" "$steamrt_sha256" \
    72 80 steamrt

/system/bin/mkdir -p "$steam_root" "$steam_root/package" "$steam_home/.steam"
seed_zip="$seed_file"
if ! /system/bin/unzip -t "$seed_file" >/dev/null 2>&1; then
    rebased_seed="$downloads/steam-seed-rebased.zip"
    "$ZIP_REBASE" "$seed_file" "$rebased_seed" || fail steam_seed_rebase
    /system/bin/unzip -t "$rebased_seed" >/dev/null 2>&1 || fail steam_seed_rebased_invalid
    seed_zip="$rebased_seed"
    log "nova_provision_steam_seed_rebase=pass prefix=$steam_seed_zip_prefix_bytes"
fi
/system/bin/unzip -q -o "$seed_zip" -d "$steam_root"
provision_progress 86 steam_seed_extract "$steam_seed_package"
# Android's toybox tar delegates -J to an Android-host xz executable, which
# is not present on a stock rooted device. Use the xz shipped by the Holo
# glibc rootfs and leave tar responsible only for the uncompressed stream.
/system/bin/cat "$runtime_file" |
    /system/bin/chroot "$rootfs" /usr/bin/xz -d -c |
    /system/bin/tar -x -f - -C "$steam_root"
[ -f "$steam_root/steam-runtime-steamrt-arm64/VERSIONS.txt" ] ||
    fail steamrt_extract_layout
provision_progress 90 steamrt_extract "$steamrt_url"

# The SteamRT archive carries fully versioned shared objects but does not
# always include the SONAME links that the ARM64 client uses for dlmopen.
# Match the established Holo deploy path and create only missing links inside
# the staged SteamRT tree.
ensure_steam_runtime_sonames "$steam_root/steam-runtime-steamrt-arm64" ||
    fail steamrt_soname_links

/system/bin/printf '%s\n' steamdeck_publicbeta >"$steam_root/package/beta"
/system/bin/ln -sfn ../.local/share/Steam "$steam_home/.steam/steam"
/system/bin/ln -sfn ../.local/share/Steam "$steam_home/.steam/root"
/system/bin/ln -sfn ../.local/share/Steam/linux32 "$steam_home/.steam/sdk32"
/system/bin/ln -sfn ../.local/share/Steam/linux64 "$steam_home/.steam/sdk64"
/system/bin/ln -sfn ../.local/share/Steam/linuxarm64 "$steam_home/.steam/sdkarm64"
/system/bin/ln -sfn ../.local/share/Steam/ubuntu12_32 "$steam_home/.steam/bin32"
/system/bin/ln -sfn ../.local/share/Steam/ubuntu12_64 "$steam_home/.steam/bin64"
/system/bin/ln -sfn steamrtarm64 "$steam_root/steamrtarm32"

ibus=$(/system/bin/find "$steam_root/steam-runtime-steamrt-arm64" \
    -path '*/files/lib/aarch64-linux-gnu/libibus-1.0.so.5.*' -type f 2>/dev/null |
    /system/bin/sort | /system/bin/tail -n 1)
if [ -n "$ibus" ]; then
    /system/bin/mkdir -p "$steam_root/lib/aarch64-linux-gnu"
    ibus_relative=${ibus#"$steam_root/"}
    /system/bin/ln -sfn "../../$ibus_relative" \
        "$steam_root/lib/aarch64-linux-gnu/libibus-1.0.so.5"
fi
for steam_path in \
    "$steam_root/steamrtarm64/steam" \
    "$steam_root/steamrtarm64/steamwebhelper" \
    "$steam_root/steamrtarm64/gldriverquery" \
    "$steam_root/steamrtarm64/vulkandriverquery"; do
    [ -e "$steam_path" ] && /system/bin/chmod 755 "$steam_path"
done

/system/bin/mkdir -p "$driver_dir" "$rootfs/opt/nova-steam/proton-tools"
driver_asset="$APP_DIR/$turnip_driver_name"
icd_asset="$APP_DIR/$turnip_icd_name"
[ -f "$driver_asset" ] || fail missing_turnip_driver_asset
[ -f "$icd_asset" ] || fail missing_turnip_icd_asset
driver_actual_sha256=$(/system/bin/sha256sum "$driver_asset" | /system/bin/awk '{ print $1 }')
driver_actual_size=$(/system/bin/wc -c <"$driver_asset" | /system/bin/tr -d '[:space:]')
[ "$driver_actual_sha256" = "$turnip_driver_sha256" ] || fail turnip_driver_sha256
[ "$driver_actual_size" = "$turnip_driver_size" ] || fail turnip_driver_size
icd_actual_sha256=$(/system/bin/sha256sum "$icd_asset" | /system/bin/awk '{ print $1 }')
[ "$icd_actual_sha256" = "$turnip_icd_sha256" ] || fail turnip_icd_sha256
/system/bin/cp "$driver_asset" "$driver_dir/$turnip_driver_name"
/system/bin/cp "$icd_asset" "$driver_dir/$turnip_icd_name"
/system/bin/chmod 755 "$driver_dir/$turnip_driver_name"
/system/bin/chmod 644 "$driver_dir/$turnip_icd_name"

for helper in nova-steam-network-api-compat.sh nova-steamos-update-compat.sh; do
    [ -f "$APP_DIR/$helper" ] || fail "missing_helper_$helper"
    /system/bin/cp "$APP_DIR/$helper" "$driver_dir/$helper"
    /system/bin/chmod 755 "$driver_dir/$helper"
done
for helper in nova-uinput-gamepad-relay libsysv-sem-shim.so \
    libnova-cef-env-split.so libffmpeg-avutil-compat.so libsdl3-compat.so \
    libposix-sync-trace.so libnova-alsa-audiotrack-bridge.so nova-mount-private; do
    if [ -f "$APP_DIR/$helper" ]; then
        /system/bin/cp "$APP_DIR/$helper" "$driver_dir/$helper"
        /system/bin/chmod 755 "$driver_dir/$helper"
    fi
done

for helper in nova-proton-11-arm64-wrapper-setup.sh \
    nova-proton-11-arm64-compatibilitytool.vdf \
    nova-proton-11-arm64-wrapper-compatibilitytool.vdf; do
    [ -f "$APP_DIR/$helper" ] || fail "missing_proton_helper_$helper"
    /system/bin/cp "$APP_DIR/$helper" "$rootfs/opt/nova-steam/proton-tools/$helper"
    /system/bin/chmod 755 "$rootfs/opt/nova-steam/proton-tools/$helper"
done

/system/bin/mkdir -p "$steam_root/steamapps/common" "$steam_root/compatibilitytools.d"
/system/bin/chown -R "$steam_uid:$steam_gid" "$steam_root"
/system/bin/chown "$steam_home_uid:$steam_home_gid" "$steam_home" \
    "$steam_home/.local" "$steam_home/.local/share"
/system/bin/chmod 755 "$steam_home" "$steam_home/.local" "$steam_home/.local/share"
/system/bin/mkdir -p "$steam_home/.steam"
/system/bin/chown "$steam_uid:$steam_gid" "$steam_home/.steam"
/system/bin/chmod 700 "$steam_home/.steam"

legacy_steam="$LEGACY_ROOT/opt/nova-steam/home/.local/share/Steam"
if [ -d "$legacy_steam" ]; then
    steam_data_policy=legacy-root-preserved-fresh-runtime-qr-login
else
    steam_data_policy=fresh-runtime-qr-login
fi
/system/bin/printf '%s\n' \
    "runtime_version=$runtime_version" \
    "rootfs_archive=$rootfs_archive" \
    "rootfs_sha256=$rootfs_sha256" \
    "steam_manifest_sha256=$steam_manifest_sha256" \
    "steam_seed_package=$steam_seed_package" \
    "steam_seed_sha256=$steam_seed_sha256" \
    "steamrt_snapshot=$(manifest_value steamrt_snapshot)" \
    "steamrt_sha256=$steamrt_sha256" \
    "package_closure_sha256=$package_closure_sha256" \
    "turnip_driver=$turnip_driver_name" \
    "turnip_driver_sha256=$turnip_driver_sha256" \
    "turnip_icd=$turnip_icd_name" \
    "turnip_icd_sha256=$turnip_icd_sha256" \
    "package_closure_count=$package_count" \
    "steam_data_policy=$steam_data_policy" \
    "auth_secrets_exported=0" \
    "gamescope_critical_path=0" \
    "ahardwarebuffer_critical_path=0" \
    >"$provisioning/artifact-hashes.tsv"
/system/bin/chmod 644 "$provisioning/artifact-hashes.tsv"

/system/bin/rm -rf "$downloads" "$work"
/system/bin/printf '%s\n' "complete=1" "activated_after_validation=1" \
    "steam_data_policy=$steam_data_policy" "auth_secrets_exported=0" \
    >"$provisioning/complete"
/system/bin/chmod 644 "$provisioning/complete"
provision_progress 100 complete "$runtime_version"
runtime_is_valid "$stage_dir" || fail staged_runtime_validation

if [ -e "$runtime_dir" ]; then
    /system/bin/rm -rf "$runtime_dir"
fi
/system/bin/mv "$stage_dir" "$runtime_dir"
stage_cleanup=0
activate_runtime "$runtime_dir"
log "nova_provision_status=pass version=$runtime_version"
if [ -d "$legacy_steam" ]; then
    log "nova_provision_rollback=available root=$LEGACY_ROOT"
fi
exit 0
