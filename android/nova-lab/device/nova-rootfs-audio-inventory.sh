#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"

printf 'rootfs=%s\n' "$ROOT"
for path in /dev/snd /run /run/pulse /run/pipewire /tmp \
    /opt/nova-steam/home/.local/share/Steam/logs; do
    printf 'PATH=%s\n' "$path"
    /system/bin/ls -ld "$ROOT$path" 2>&1 || true
done

for name in pactl pulseaudio pipewire pw-cli aplay arecord; do
    printf 'BIN=%s ' "$name"
    if [ -x "$ROOT/usr/bin/$name" ]; then
        printf 'present\n'
    else
        printf 'absent\n'
    fi
done
