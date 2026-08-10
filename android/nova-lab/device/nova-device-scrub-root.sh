#!/system/bin/sh

# Exact-scope device cleanup for Nova experiments. The host wrapper performs
# the package stop/uninstall and records the before/after inventory. This root
# half only removes resolved top-level Nova artifacts and the two explicitly
# identified non-Nova-prefixed project files.

set -eu

SCRUB_SCRIPT=/data/local/tmp/nova-device-scrub-root.sh

if [ "$(/system/bin/id -u)" != 0 ]; then
    echo "nova_device_scrub=fail reason=root_required" >&2
    exit 1
fi

# A prior direct-root launcher can leave the extracted Holo rootfs with
# read-only system/APEX mount views. Detach only mountpoints whose targets
# are inside the explicitly authorized Nova temporary namespace before
# removing anything. Deleting a mounted directory would otherwise recurse
# into Android's protected mount views and produce a misleading partial scrub.
nova_mounts=$(/system/bin/mount | /system/bin/awk \
    '$3 ~ /^\/data\/local\/tmp\/nova/ {print $3}' | \
    /system/bin/sort -u -r)
for mountpoint in $nova_mounts; do
    case "$mountpoint" in
        /data/local/tmp/nova*)
            /system/bin/umount "$mountpoint" 2>/dev/null || \
                /system/bin/umount -l "$mountpoint"
            ;;
        *)
            echo "nova_device_scrub=fail reason=unexpected_mount path=$mountpoint" >&2
            exit 1
            ;;
    esac
done

remaining_mounts=$(/system/bin/mount | /system/bin/awk \
    '$3 ~ /^\/data\/local\/tmp\/nova/ {print $3}' | \
    /system/bin/sort -u -r)
if [ -n "$remaining_mounts" ]; then
    echo "nova_device_scrub=fail reason=mounted_nova_path path=$remaining_mounts" >&2
    exit 1
fi

for path in $(/system/bin/find /data/local/tmp -maxdepth 1 -mindepth 1 \
    -name 'nova*' -print 2>/dev/null); do
    if [ "$path" = "$SCRUB_SCRIPT" ]; then
        continue
    fi
    case "$path" in
        /data/local/tmp/nova*)
            /system/bin/rm -rf "$path"
            ;;
        *)
            echo "nova_device_scrub=fail reason=unexpected_path path=$path" >&2
            exit 1
            ;;
    esac
done

for path in \
    /data/local/tmp/audio-20260809T230053Z-steam-alsa-group \
    /data/local/tmp/launcher-20260809T223146Z-x11-custom-1280x960-termux-x11-preferences.xml; do
    if [ -e "$path" ]; then
        /system/bin/rm -rf "$path"
    fi
done

/system/bin/rm -f "$SCRUB_SCRIPT"
echo "nova_device_scrub=pass scope=/data/local/tmp/nova*-and-listed-project-artifacts"
