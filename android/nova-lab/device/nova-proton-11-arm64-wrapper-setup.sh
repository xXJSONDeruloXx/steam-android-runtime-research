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
            /system/bin/ln -s "$path" "$WRAPPER_ROOT/$name"
            ;;
    esac
done
/system/bin/cp "$PROTON_ROOT/toolmanifest.vdf" "$WRAPPER_ROOT/toolmanifest.vdf"
/system/bin/sed -i '/require_tool_appid[[:space:]]*"4185400"/d' \
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
