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
