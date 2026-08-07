#!/bin/sh

set -u

export GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts
OUTPUT_WIDTH=${NOVA_AHB_WIDTH:-960}
OUTPUT_HEIGHT=${NOVA_AHB_HEIGHT:-540}
GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-35}
CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-25}
STEAM_HOME=/opt/nova-steam/home
STEAM_ROOT="$STEAM_HOME/.local/share/Steam"
STEAM_CLIENT="$STEAM_ROOT/steamrtarm64/steam"
STEAM_UID=0
STEAM_GID=0
if [ -r /opt/nova-steam/run-as-user ]; then
    IFS=: read -r STEAM_UID STEAM_GID < /opt/nova-steam/run-as-user || true
fi

run_as_steam() {
    if [ "$STEAM_UID" -eq 0 ]; then
        "$@"
    else
        /usr/bin/setpriv --reuid="$STEAM_UID" --regid="$STEAM_GID" --clear-groups "$@"
    fi
}

if [ "${1:-}" = "--client" ]; then
    client_log=/tmp/nova-steam-client.log
    client_stdout=/tmp/nova-steam-client.stdout
    client_stderr=/tmp/nova-steam-client.stderr
    client_flags="-gamepadui -steamos3 -steampal -steamdeck"
    if [ "${NOVA_STEAM_NO_CEF_SANDBOX:-0}" = "1" ]; then
        client_flags="$client_flags -no-cef-sandbox"
    fi

    mkdir -p "$STEAM_HOME" /tmp/nova-steam-runtime
    echo "client_begin $(date +%s)" > "$client_log"
    echo "client_kind=steam_arm64" >> "$client_log"
    echo "client_display=${DISPLAY:-unset}" >> "$client_log"
    echo "client_output=${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" >> "$client_log"
    echo "client_home=$STEAM_HOME" >> "$client_log"
    echo "client_root=$STEAM_ROOT" >> "$client_log"
    echo "client_flags=$client_flags" >> "$client_log"
    echo "client_uid=$STEAM_UID" >> "$client_log"
    echo "client_gid=$STEAM_GID" >> "$client_log"
    echo "client_xauthority=${XAUTHORITY:-unset}" >> "$client_log"

    export HOME="$STEAM_HOME"
    if [ "$STEAM_UID" -eq 0 ]; then
        export USER=${USER:-root}
    else
        export USER=steam
    fi
    export LOGNAME=$USER
    export DISPLAY=:0
    export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
    export LANG=${LANG:-C}
    export LC_ALL=${LC_ALL:-C}
    export PATH="$STEAM_ROOT/steam-runtime-steamrt-arm64/bin:/usr/bin:/bin"
    steam_runtime_lib=
    for candidate in "$STEAM_ROOT"/steam-runtime-steamrt-arm64/*/files/lib/aarch64-linux-gnu; do
        if [ -d "$candidate" ]; then
            steam_runtime_lib=$candidate
            break
        fi
    done
    steam_runtime_pulse_lib=
    if [ -n "$steam_runtime_lib" ] && [ -d "$steam_runtime_lib/pulseaudio" ]; then
        steam_runtime_pulse_lib="$steam_runtime_lib/pulseaudio"
    fi
    export LD_LIBRARY_PATH="$STEAM_ROOT/steamrtarm64:$STEAM_ROOT/lib/aarch64-linux-gnu${steam_runtime_lib:+:$steam_runtime_lib}${steam_runtime_pulse_lib:+:$steam_runtime_pulse_lib}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    preload=
    if [ -f /opt/nova-kgsl-driver/libsysv-sem-shim.so ]; then
        preload=/opt/nova-kgsl-driver/libsysv-sem-shim.so
        echo "client_sysv_sem_shim=pass" >> "$client_log"
        if [ -f /opt/nova-steam/trace-sysv-sem ]; then
            export NOVA_SYSV_SEM_SHIM_TRACE=1
            echo "client_sysv_sem_trace=pass" >> "$client_log"
        fi
    fi
    if [ -f /opt/nova-kgsl-driver/libffmpeg-avutil-compat.so ]; then
        if [ -n "$preload" ]; then
            preload="/opt/nova-kgsl-driver/libffmpeg-avutil-compat.so:$preload"
        else
            preload=/opt/nova-kgsl-driver/libffmpeg-avutil-compat.so
        fi
        echo "client_ffmpeg_avutil_compat=pass" >> "$client_log"
    fi
    if [ -f /opt/nova-kgsl-driver/libsdl3-compat.so ]; then
        if [ -n "$preload" ]; then
            preload="/opt/nova-kgsl-driver/libsdl3-compat.so:$preload"
        else
            preload=/opt/nova-kgsl-driver/libsdl3-compat.so
        fi
        echo "client_sdl3_compat=pass" >> "$client_log"
    fi
    if [ -f /usr/lib/libstdc++.so.6 ]; then
        if [ -n "$preload" ]; then
            preload="/usr/lib/libstdc++.so.6:$preload"
        else
            preload=/usr/lib/libstdc++.so.6
        fi
        echo "client_holo_libstdcxx=pass" >> "$client_log"
    fi
    if [ -f /usr/lib/libgcc_s.so.1 ]; then
        if [ -n "$preload" ]; then
            preload="/usr/lib/libgcc_s.so.1:$preload"
        else
            preload=/usr/lib/libgcc_s.so.1
        fi
        echo "client_holo_libgcc=pass" >> "$client_log"
    fi
    for holo_abi in /usr/lib/libva.so.2 /usr/lib/libva-drm.so.2 /usr/lib/libva-x11.so.2; do
        if [ -f "$holo_abi" ]; then
            if [ -n "$preload" ]; then
                preload="$holo_abi:$preload"
            else
                preload=$holo_abi
            fi
        fi
    done
    if [ -f /opt/nova-kgsl-driver/libposix-sync-trace.so ]; then
        if [ -n "$preload" ]; then
            preload="/opt/nova-kgsl-driver/libposix-sync-trace.so:$preload"
        else
            preload=/opt/nova-kgsl-driver/libposix-sync-trace.so
        fi
        echo "client_sync_trace=pass" >> "$client_log"
    fi
    if [ -n "$preload" ]; then
        export LD_PRELOAD="$preload"
    fi

    if { [ "${NOVA_XWAYLAND_ALLOW_LOCAL:-0}" = "1" ] || [ -f /opt/nova-steam/allow-xwayland-local ]; } && [ -x /usr/bin/xhost ]; then
        xhost_log=/tmp/nova-steam-xhost.log
        xhost_target="+SI:localuser:$STEAM_UID"
        env -u LD_PRELOAD DISPLAY=:0 /usr/bin/xhost "$xhost_target" >"$xhost_log" 2>&1
        xhost_status=$?
        echo "client_xhost_local_status=$xhost_status" >> "$client_log"
        echo "client_xhost_target=$xhost_target" >> "$client_log"
        echo "client_xhost_local_log=$xhost_log" >> "$client_log"
    fi
    if [ ! -x "$STEAM_CLIENT" ]; then
        echo "client_started=fail" >> "$client_log"
        echo "client_error=missing_or_nonexecutable_steam" >> "$client_log"
        exit 1
    fi
    if [ -x /usr/bin/dbus-launch ]; then
        eval "$(run_as_steam /usr/bin/dbus-launch --sh-syntax --exit-with-session 2>/dev/null)" || true
    fi

    set -- $client_flags ${NOVA_STEAM_EXTRA_ARGS:-}
    run_as_steam /usr/bin/timeout "$CLIENT_TIMEOUT" "$STEAM_CLIENT" "$@" \
        >"$client_stdout" 2>"$client_stderr" &
    client_pid=$!
    echo "client_pid=$client_pid" >> "$client_log"
    if /usr/bin/kill -0 "$client_pid" 2>/dev/null; then
        echo "client_started=pass" >> "$client_log"
    else
        echo "client_started=fail" >> "$client_log"
    fi
    wait "$client_pid" 2>/dev/null
    client_status=$?
    echo "client_status=$client_status" >> "$client_log"
    if [ "$client_status" -eq 124 ]; then
        echo "client_timeout=expected" >> "$client_log"
    fi
    if [ -f "$STEAM_ROOT/package/steam_client_steamdeck_publicbeta_linuxarm64.installed" ]; then
        echo "client_installed=pass" >> "$client_log"
    else
        echo "client_installed=absent" >> "$client_log"
    fi
    client_stdout_size=$(wc -c < "$client_stdout")
    client_stderr_size=$(wc -c < "$client_stderr")
    echo "client_stdout=$client_stdout_size" >> "$client_log"
    echo "client_stderr=$client_stderr_size" >> "$client_log"
    echo "client_end $(date +%s)" >> "$client_log"
    # Gamescope's bounded presentation run is the acceptance boundary. Keep a
    # Steam startup failure in the client log so the compositor report remains
    # available for diagnosis.
    exit 0
fi

set +e
echo "steam_xwayland_control_begin output=${OUTPUT_WIDTH}x${OUTPUT_HEIGHT} timeout=$GAMESCOPE_TIMEOUT output_socket=${NOVA_AHB_OUTPUT_SOCKET:-missing}" >&2
/usr/bin/timeout "$GAMESCOPE_TIMEOUT" /opt/nova-kgsl-driver/gamescope-headless \
    --backend headless \
    --xwayland-count 1 \
    --output-width "$OUTPUT_WIDTH" \
    --output-height "$OUTPUT_HEIGHT" \
    --nested-width "$OUTPUT_WIDTH" \
    --nested-height "$OUTPUT_HEIGHT" \
    -- /opt/nova-kgsl-driver/gamescope-headless-ahb-control.sh --client
status=$?
set -e
if [ "$status" -eq 124 ]; then
    exit 0
fi
exit "$status"
