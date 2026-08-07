#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="${NOVA_STEAM_OUTPUT_DIR:-$BUILD_DIR/steam-arm64}"
PACKAGE_DIR="$OUTPUT_DIR/package"
STEAM_ARM_CHANNEL="${STEAM_ARM_CHANNEL:-steamdeck_publicbeta}"
MANIFEST_NAME="steam_client_${STEAM_ARM_CHANNEL}_linuxarm64"
MANIFEST="$PACKAGE_DIR/$MANIFEST_NAME.manifest"
METADATA="$OUTPUT_DIR/metadata.tsv"
STEAM_CDN="${STEAM_ARM_CDN:-https://client-update.steamstatic.com}"
STEAM_ARM_MANIFEST_URL="$STEAM_CDN/$MANIFEST_NAME"
STEAMRT_BASE="${STEAMRT_BASE:-https://repo.steampowered.com/steamrt3c/images}"
STEAMRT_CHANNEL="${STEAMRT_CHANNEL:-latest-public-beta}"

usage() {
    cat <<'EOF'
Usage: fetch-steam-arm64-seed.sh [--metadata-only|--seed|--runtime|--all]

Resolve Valve's native ARM64 Steam channel and write disposable artifacts under
android/nova-lab/build/steam-arm64/. The default is metadata-only; downloads are
opt-in because the seed and runtime are large and must not enter git.

  --metadata-only  Fetch and parse the manifest and SteamRT pointer only (default)
  --seed            Also download and verify the native ARM64 Steam seed zip
  --runtime         Also download and verify the SteamRT3C ARM64 runtime archive
  --all             Download and verify both artifacts

Environment:
  NOVA_STEAM_OUTPUT_DIR  Override the ignored output directory
  STEAM_ARM_CHANNEL      Valve client channel (default: steamdeck_publicbeta)
  STEAMRT_CHANNEL        SteamRT3C channel (default: latest-public-beta)
EOF
}

mode=metadata-only
case "${1:-}" in
    "") ;;
    --metadata-only|--seed|--runtime|--all) mode=${1#--} ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

download() {
    local url=$1
    local destination=$2
    local expected_size=${3:-}
    local expected_sha256=${4:-}
    local partial="$destination.part"

    if [ -f "$destination" ]; then
        local cached_size
        cached_size=$(wc -c < "$destination" | tr -d '[:space:]')
        if [ -n "$expected_size" ] && [ "$cached_size" != "$expected_size" ]; then
            echo "discarding cached size mismatch: $destination ($cached_size != $expected_size)" >&2
            rm -f "$destination"
        elif [ -n "$expected_sha256" ] && [ "$(sha256_file "$destination")" != "$expected_sha256" ]; then
            echo "discarding cached SHA-256 mismatch: $destination" >&2
            rm -f "$destination"
        else
            echo "cached=$destination"
            return 0
        fi
    fi

    mkdir -p "$(dirname "$destination")"
    if [ -f "$partial" ]; then
        curl --fail --location --retry 5 --retry-delay 3 --connect-timeout 20 \
            --continue-at - --output "$partial" "$url"
    else
        curl --fail --location --retry 5 --retry-delay 3 --connect-timeout 20 \
            --output "$partial" "$url"
    fi
    mv "$partial" "$destination"

    local actual_size
    actual_size=$(wc -c < "$destination" | tr -d '[:space:]')
    if [ -n "$expected_size" ] && [ "$actual_size" != "$expected_size" ]; then
        echo "downloaded size mismatch: $destination ($actual_size != $expected_size)" >&2
        exit 1
    fi
    if [ -n "$expected_sha256" ]; then
        local actual_sha256
        actual_sha256=$(sha256_file "$destination")
        if [ "$actual_sha256" != "$expected_sha256" ]; then
            echo "downloaded SHA-256 mismatch: $destination ($actual_sha256 != $expected_sha256)" >&2
            exit 1
        fi
    fi
    echo "downloaded=$destination"
}

mkdir -p "$PACKAGE_DIR"
download "$STEAM_ARM_MANIFEST_URL" "$MANIFEST"
manifest_sha256=$(sha256_file "$MANIFEST")

runtime_snapshot=$(curl --fail --location --retry 5 --retry-delay 3 --connect-timeout 20 \
    "$STEAMRT_BASE/$STEAMRT_CHANNEL.txt" | tr -d '[:space:]')
if [[ ! "$runtime_snapshot" =~ ^[0-9a-zA-Z._-]+$ ]]; then
    echo "invalid SteamRT snapshot: $runtime_snapshot" >&2
    exit 1
fi

runtime_url="$STEAMRT_BASE/$runtime_snapshot/steam-runtime-steamrt-arm64.tar.xz"
runtime_headers=$(curl --fail --location --retry 5 --retry-delay 3 --connect-timeout 20 \
    --head "$runtime_url")
runtime_size=$(printf '%s\n' "$runtime_headers" | awk 'tolower($1) == "content-length:" {gsub(/\r/, "", $2); print $2; exit}')
if [[ ! "$runtime_size" =~ ^[0-9]+$ ]]; then
    echo "could not determine SteamRT runtime size from HEAD: $runtime_url" >&2
    exit 1
fi

python3 - "$MANIFEST" "$METADATA" <<'PY'
import pathlib
import re
import sys

manifest_path = pathlib.Path(sys.argv[1])
metadata_path = pathlib.Path(sys.argv[2])
text = manifest_path.read_text(errors="strict")

if not text.startswith('"linuxarm64"'):
    raise SystemExit("manifest does not identify linuxarm64")

version_match = re.search(r'"version"\s+"([0-9]+)"', text)
entry_match = re.search(
    r'"bins_linuxarm64_linuxarm64"\s*\{(?P<body>.*?)\n\s*\}',
    text,
    re.DOTALL,
)
if not version_match or not entry_match:
    raise SystemExit("manifest is missing version or ARM64 seed entry")

body = entry_match.group("body")


def get_value(name: str) -> str:
    match = re.search(rf'"{name}"\s+"([^"]+)"', body)
    if not match:
        raise SystemExit(f"manifest seed entry is missing {name}")
    return match.group(1)


seed_package = get_value("file")
seed_size = get_value("size")
seed_sha256 = get_value("sha2")
if ".zip.vz." in seed_package or not re.fullmatch(
    r"bins_linuxarm64_linuxarm64\.zip\.[0-9a-f]+", seed_package
):
    raise SystemExit(f"manifest selected an unexpected seed package: {seed_package}")
if not re.fullmatch(r"[0-9]+", seed_size) or not re.fullmatch(r"[0-9a-f]{64}", seed_sha256):
    raise SystemExit("manifest seed metadata has an unexpected format")

metadata = {
    "manifest_name": manifest_path.name.removesuffix(".manifest"),
    "manifest_sha256": "PLACEHOLDER",
    "client_version": version_match.group(1),
    "seed_package": seed_package,
    "seed_size": seed_size,
    "seed_sha256": seed_sha256,
}
metadata_path.write_text("".join(f"{key}\t{value}\n" for key, value in metadata.items()))
PY

runtime_pointer="$OUTPUT_DIR/$STEAMRT_CHANNEL.txt"
printf '%s\n' "$runtime_snapshot" > "$runtime_pointer"
runtime_pointer_sha256=$(sha256_file "$runtime_pointer")

python3 - "$METADATA" "$manifest_sha256" "$runtime_snapshot" "$runtime_url" "$runtime_size" "$runtime_pointer_sha256" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
values = {}
for line in path.read_text().splitlines():
    key, value = line.split("\t", 1)
    values[key] = value
values.update(
    manifest_sha256=sys.argv[2],
    runtime_snapshot=sys.argv[3],
    runtime_url=sys.argv[4],
    runtime_size=sys.argv[5],
    runtime_pointer_sha256=sys.argv[6],
)
path.write_text("".join(f"{key}\t{value}\n" for key, value in values.items()))
PY

metadata_value() {
    awk -F '\t' -v key="$1" '$1 == key { print $2; exit }' "$METADATA"
}

seed_package=$(metadata_value seed_package)
seed_size=$(metadata_value seed_size)
seed_sha256=$(metadata_value seed_sha256)
runtime_url=$(metadata_value runtime_url)
runtime_size=$(metadata_value runtime_size)

seed_path="$PACKAGE_DIR/$seed_package"
runtime_path="$OUTPUT_DIR/steam-runtime-steamrt-arm64.tar.xz"

case "$mode" in
    seed)
        download "$STEAM_CDN/$seed_package" "$seed_path" "$seed_size" "$seed_sha256"
        ;;
    runtime)
        download "$runtime_url" "$runtime_path" "$runtime_size"
        ;;
    all)
        download "$STEAM_CDN/$seed_package" "$seed_path" "$seed_size" "$seed_sha256"
        download "$runtime_url" "$runtime_path" "$runtime_size"
        ;;
esac

echo "metadata=$METADATA"
echo "client_version=$(metadata_value client_version)"
echo "seed_package=$seed_package"
echo "seed_size=$seed_size"
echo "runtime_snapshot=$(metadata_value runtime_snapshot)"
echo "runtime_size=$runtime_size"
if [ "$mode" != "metadata-only" ]; then
    echo "steam_output=$OUTPUT_DIR"
fi
