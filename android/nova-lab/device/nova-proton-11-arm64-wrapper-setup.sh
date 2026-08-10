#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
COMPATIBILITY_VDF="${2:-}"
STEAM_ROOT="$ROOT/opt/nova-steam/home/.local/share/Steam"
PROTON_ROOT="$STEAM_ROOT/steamapps/common/Proton 11.0 (ARM64)"
WRAPPER_ROOT="$STEAM_ROOT/compatibilitytools.d/proton-11-arm64"

if [ ! -d "$PROTON_ROOT" ] || [ ! -f "$PROTON_ROOT/toolmanifest.vdf" ]; then
    echo "proton11_wrapper=fail reason=missing_proton_root path=$PROTON_ROOT" >&2
    exit 1
fi
if [ -e "$WRAPPER_ROOT" ]; then
    echo "proton11_wrapper=fail reason=existing_wrapper path=$WRAPPER_ROOT" >&2
    exit 2
fi
if [ -z "$COMPATIBILITY_VDF" ] || [ ! -f "$COMPATIBILITY_VDF" ]; then
    echo "proton11_wrapper=fail reason=missing_compatibility_vdf" >&2
    exit 1
fi

/system/bin/mkdir -p "$WRAPPER_ROOT"
for path in "$PROTON_ROOT"/*; do
    name="${path##*/}"
    case "$name" in
        toolmanifest.vdf)
            ;;
        *)
            # The wrapper is executed after chroot. An Android-visible
            # absolute target such as /data/local/tmp/nova-holo-rootfs/... is
            # outside that chroot and becomes a broken link there. Keep the
            # link relative to the Steam tree so both views resolve it.
            /system/bin/ln -s "../../steamapps/common/Proton 11.0 (ARM64)/$name" \
                "$WRAPPER_ROOT/$name"
            ;;
    esac
done

proton_link_target="$(/system/bin/readlink "$WRAPPER_ROOT/proton" 2>/dev/null || true)"
case "$proton_link_target" in
    "")
        echo "proton11_wrapper=fail reason=missing_proton_link" >&2
        exit 3
        ;;
    /*)
        echo "proton11_wrapper=fail reason=absolute_proton_link target=$proton_link_target" >&2
        exit 3
        ;;
esac
if [ ! -e "$WRAPPER_ROOT/proton" ] || \
    [ ! -e "$WRAPPER_ROOT/files/bin-arm64/wine" ]; then
    echo "proton11_wrapper=fail reason=broken_chroot_visible_link" >&2
    exit 3
fi

/system/bin/cp "$PROTON_ROOT/toolmanifest.vdf" "$WRAPPER_ROOT/toolmanifest.vdf"
/system/bin/sed -i '/4185400/d' \
    "$WRAPPER_ROOT/toolmanifest.vdf"
/system/bin/cp "$COMPATIBILITY_VDF" "$WRAPPER_ROOT/compatibilitytool.vdf"
/system/bin/chown 501:20 "$WRAPPER_ROOT" "$WRAPPER_ROOT/toolmanifest.vdf" \
    "$WRAPPER_ROOT/compatibilitytool.vdf"
/system/bin/chmod 755 "$WRAPPER_ROOT"
/system/bin/chmod 644 "$WRAPPER_ROOT/toolmanifest.vdf" \
    "$WRAPPER_ROOT/compatibilitytool.vdf"

echo "proton11_wrapper=pass path=$WRAPPER_ROOT"
/system/bin/sha256sum "$PROTON_ROOT/toolmanifest.vdf" "$WRAPPER_ROOT/toolmanifest.vdf" \
    "$WRAPPER_ROOT/compatibilitytool.vdf"
