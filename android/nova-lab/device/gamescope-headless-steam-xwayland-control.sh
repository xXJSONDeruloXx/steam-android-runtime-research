#!/bin/sh

set -u

export GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts
OUTPUT_WIDTH=${NOVA_AHB_WIDTH:-960}
OUTPUT_HEIGHT=${NOVA_AHB_HEIGHT:-540}
GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-35}
CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-25}
NOVA_AHB_TRACE=${NOVA_AHB_TRACE:-0}
NOVA_AHB_SOCKET_TRACE=${NOVA_AHB_SOCKET_TRACE:-0}
if [ -r /opt/nova-steam/gamescope-timeout ]; then
    GAMESCOPE_TIMEOUT=$(cat /opt/nova-steam/gamescope-timeout)
fi
if [ -r /opt/nova-steam/client-timeout ]; then
    CLIENT_TIMEOUT=$(cat /opt/nova-steam/client-timeout)
fi
if [ -r /opt/nova-steam/ahb-trace ]; then
    NOVA_AHB_TRACE=$(cat /opt/nova-steam/ahb-trace)
fi
if [ -r /opt/nova-steam/ahb-socket-trace ]; then
    NOVA_AHB_SOCKET_TRACE=$(cat /opt/nova-steam/ahb-socket-trace)
fi
export NOVA_AHB_TRACE
export NOVA_AHB_SOCKET_TRACE
EIS_TOUCH_BRIDGE=0
EIS_TOUCH_HELPER=/opt/nova-kgsl-driver/nova-libei-input-bridge
EIS_TOUCH_APP_SOCKET=/run/nova-lab-app/nova-touch.sock
EIS_TOUCH_TIMEOUT=60000
EIS_TOUCH_CONTINUOUS=0
if [ -r /opt/nova-steam/eis-touch-bridge ]; then
    EIS_TOUCH_BRIDGE=$(cat /opt/nova-steam/eis-touch-bridge)
fi
if [ -r /opt/nova-steam/eis-touch-helper ]; then
    EIS_TOUCH_HELPER=$(cat /opt/nova-steam/eis-touch-helper)
fi
if [ -r /opt/nova-steam/eis-touch-app-socket ]; then
    EIS_TOUCH_APP_SOCKET=$(cat /opt/nova-steam/eis-touch-app-socket)
fi
if [ -r /opt/nova-steam/eis-touch-timeout ]; then
    EIS_TOUCH_TIMEOUT=$(cat /opt/nova-steam/eis-touch-timeout)
fi
if [ -r /opt/nova-steam/eis-touch-continuous ]; then
    EIS_TOUCH_CONTINUOUS=$(cat /opt/nova-steam/eis-touch-continuous)
fi
case "$EIS_TOUCH_TIMEOUT" in
    ''|*[!0-9]*)
        EIS_TOUCH_TIMEOUT=60000
        ;;
esac
EIS_TOUCH_TIMEOUT_SECONDS=$(( (EIS_TOUCH_TIMEOUT + 999) / 1000 ))
touch_app_socket_ready() {
    case "$EIS_TOUCH_APP_SOCKET" in
        @*) return 0 ;;
        *) [ -S "$EIS_TOUCH_APP_SOCKET" ] ;;
    esac
}
STEAM_HOME=/opt/nova-steam/home
STEAM_ROOT="$STEAM_HOME/.local/share/Steam"
STEAM_CLIENT="$STEAM_ROOT/steamrtarm64/steam"
STEAM_EXECUTABLE=${NOVA_STEAM_EXECUTABLE:-$STEAM_CLIENT}
if [ -r /opt/nova-steam/executable ]; then
    STEAM_EXECUTABLE=$(cat /opt/nova-steam/executable)
fi
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
    network_compat_helper=${NOVA_STEAM_NETWORK_API_COMPAT_HELPER:-/opt/nova-kgsl-driver/nova-steam-network-api-compat.sh}
    client_flags="${NOVA_STEAM_CLIENT_FLAGS:--gamepadui -steamos3 -steampal -steamdeck}"
    bootstrap_mode=${NOVA_STEAM_BOOTSTRAP_MODE:-auto}
    if [ "$bootstrap_mode" = "auto" ] && [ "${NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP:-0}" = "1" ]; then
        bootstrap_mode=skip
    fi
    case "$bootstrap_mode" in
        auto|normal)
            ;;
        skip)
            client_flags="$client_flags -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui"
            ;;
        skip-child)
            client_flags="$client_flags -nobootstrapperupdate -skipinitialbootstrap"
            ;;
        console)
            client_flags="$client_flags -nobootstrapperupdate -skipinitialbootstrap -console"
            ;;
        inhibit)
            client_flags="$client_flags -inhibitbootstrap -no-child-update-ui"
            ;;
        *)
            echo "client_error=unknown_bootstrap_mode:$bootstrap_mode" >&2
            exit 2
            ;;
    esac
    if [ "$bootstrap_mode" != "normal" ] && [ "$bootstrap_mode" != "auto" ]; then
        rm -f \
            "$STEAM_HOME/.steam/steam.pid" \
            "$STEAM_HOME/.steam/steam.token" \
            "$STEAM_HOME/.steam/steam.pipe" \
            "$STEAM_HOME/.steam/registry.vdf" \
            "$STEAM_ROOT/registry.vdf" \
            "$STEAM_ROOT/.crash"
    fi
    if [ "${NOVA_STEAM_NO_CEF_SANDBOX:-0}" = "1" ]; then
        client_flags="$client_flags -no-cef-sandbox"
    fi

    runtime_dir=/tmp/nova-steam-runtime
    mkdir -p "$STEAM_HOME" "$runtime_dir"
    runtime_owner_status=pass
    if [ "$STEAM_UID" -eq 0 ]; then
        chmod 700 "$runtime_dir"
    elif chown "$STEAM_UID:$STEAM_GID" "$runtime_dir" && chmod 700 "$runtime_dir"; then
        :
    else
        runtime_owner_status=fail
    fi
    echo "client_begin $(date +%s)" > "$client_log"
    echo "client_kind=steam_arm64" >> "$client_log"
    echo "client_display=${DISPLAY:-unset}" >> "$client_log"
    echo "client_output=${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" >> "$client_log"
    echo "client_home=$STEAM_HOME" >> "$client_log"
    echo "client_root=$STEAM_ROOT" >> "$client_log"
    echo "client_executable=$STEAM_EXECUTABLE" >> "$client_log"
    echo "client_bootstrap_mode=$bootstrap_mode" >> "$client_log"
    echo "client_flags=$client_flags" >> "$client_log"
    echo "client_uid=$STEAM_UID" >> "$client_log"
    echo "client_gid=$STEAM_GID" >> "$client_log"
    echo "client_xauthority=${XAUTHORITY:-unset}" >> "$client_log"
    echo "client_runtime_dir=$runtime_dir" >> "$client_log"
    echo "client_runtime_owner_status=$runtime_owner_status" >> "$client_log"
    if [ "${NOVA_STEAM_NETWORK_API_COMPAT:-1}" = "1" ]; then
        if [ ! -x "$network_compat_helper" ]; then
            echo "client_network_api_compat=fail reason=missing_helper path=$network_compat_helper" >> "$client_log"
            exit 1
        fi
        "$network_compat_helper" "$STEAM_ROOT" >> "$client_log" 2>&1
        network_compat_status=$?
        echo "client_network_api_compat_status=$network_compat_status" >> "$client_log"
        if [ "$network_compat_status" -ne 0 ]; then
            exit 1
        fi
    else
        echo "client_network_api_compat=disabled" >> "$client_log"
    fi

    export HOME="$STEAM_HOME"
    if [ "$STEAM_UID" -eq 0 ]; then
        export USER=${USER:-root}
    else
        export USER=steam
    fi
    export LOGNAME=$USER
    export DISPLAY=:0
    export XDG_RUNTIME_DIR=$runtime_dir
    export LANG=${LANG:-C}
    export LC_ALL=${LC_ALL:-C}
    steam_runtime_files_bin=
    for candidate in "$STEAM_ROOT"/steam-runtime-steamrt-arm64/*/files/bin; do
        if [ -d "$candidate" ]; then
            steam_runtime_files_bin=$candidate
            break
        fi
    done
    export PATH="$STEAM_ROOT/steam-runtime-steamrt-arm64/bin${steam_runtime_files_bin:+:$steam_runtime_files_bin}:/usr/bin:/bin"
    echo "client_runtime_files_bin=${steam_runtime_files_bin:-unset}" >> "$client_log"
    export MESA_LOADER_DRIVER_OVERRIDE=${NOVA_STEAM_MESA_DRIVER:-msm}
    echo "client_mesa_driver=$MESA_LOADER_DRIVER_OVERRIDE" >> "$client_log"
    if [ -n "${NOVA_STEAM_GALLIUM_DRIVER:-}" ]; then
        export GALLIUM_DRIVER=$NOVA_STEAM_GALLIUM_DRIVER
        echo "client_gallium_driver=$GALLIUM_DRIVER" >> "$client_log"
    fi
    if [ "${NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE:-0}" = "1" ]; then
        export LIBGL_ALWAYS_SOFTWARE=1
        echo "client_libgl_always_software=1" >> "$client_log"
    fi
    if [ "${NOVA_STEAM_LIBGL_ALWAYS_INDIRECT:-0}" = "1" ]; then
        export LIBGL_ALWAYS_INDIRECT=1
        echo "client_libgl_always_indirect=1" >> "$client_log"
    fi
    if [ -n "${NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH:-}" ]; then
        export LP_NATIVE_VECTOR_WIDTH=$NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH
        echo "client_lp_native_vector_width=$LP_NATIVE_VECTOR_WIDTH" >> "$client_log"
    fi
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
    # Keep the Holo Mesa stack ahead of SteamRT's Mesa libraries. SteamRT's
    # libgbm/libEGL_mesa pair expects its own DRI driver ABI; mixing it with
    # Holo's unified KGSL DRI library reaches a null backend callback during
    # GLX initialization. Holo's non-Mesa runtime libraries remain below the
    # SteamRT paths and are still available through the normal loader search.
    export LD_LIBRARY_PATH="$STEAM_ROOT/steamrtarm64:$STEAM_ROOT/lib/aarch64-linux-gnu:/usr/lib${steam_runtime_lib:+:$steam_runtime_lib}${steam_runtime_pulse_lib:+:$steam_runtime_pulse_lib}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
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

    eis_touch_pid=
    eis_touch_log=/tmp/nova-eis-touch.log
    cleanup_eis_touch() {
        if [ -n "${eis_touch_pid:-}" ]; then
            /usr/bin/kill "$eis_touch_pid" 2>/dev/null || true
            /usr/bin/wait "$eis_touch_pid" 2>/dev/null || true
            eis_touch_pid=
        fi
        if [ -f "$eis_touch_log" ]; then
            cat "$eis_touch_log" >&2
        fi
    }
    trap cleanup_eis_touch EXIT
    if [ "$EIS_TOUCH_BRIDGE" = "1" ] && [ -x "$EIS_TOUCH_HELPER" ]; then
        eis_touch_attempt=0
        while [ "$eis_touch_attempt" -lt 100 ]; do
            if [ -S /tmp/gamescope-0-ei ] && touch_app_socket_ready; then
                break
            fi
            /usr/bin/sleep 0.1
            eis_touch_attempt=$((eis_touch_attempt + 1))
        done
        if [ -S /tmp/gamescope-0-ei ] && touch_app_socket_ready; then
            if [ "$EIS_TOUCH_CONTINUOUS" = "1" ]; then
                /usr/bin/timeout "$EIS_TOUCH_TIMEOUT_SECONDS" "$EIS_TOUCH_HELPER" \
                    /tmp/gamescope-0-ei "$EIS_TOUCH_APP_SOCKET" "$EIS_TOUCH_TIMEOUT" continuous \
                    >"$eis_touch_log" 2>&1 &
            else
                /usr/bin/timeout "$EIS_TOUCH_TIMEOUT_SECONDS" "$EIS_TOUCH_HELPER" \
                    /tmp/gamescope-0-ei "$EIS_TOUCH_APP_SOCKET" "$EIS_TOUCH_TIMEOUT" \
                    >"$eis_touch_log" 2>&1 &
            fi
            eis_touch_pid=$!
            echo "eis_touch_bridge=started helper=$EIS_TOUCH_HELPER app_socket=$EIS_TOUCH_APP_SOCKET" >&2
        else
            echo "eis_touch_bridge=unavailable gamescope_socket=/tmp/gamescope-0-ei app_socket=$EIS_TOUCH_APP_SOCKET" >&2
        fi
    fi
    if [ "${NOVA_STEAM_DISABLE_PRELOAD:-0}" = "1" ]; then
        unset LD_PRELOAD
        echo "client_preload=disabled" >> "$client_log"
    else
        case "${NOVA_STEAM_PRELOAD_PROFILE:-full}" in
            full)
                ;;
            none)
                preload=
                ;;
            sysv)
                preload=/opt/nova-kgsl-driver/libsysv-sem-shim.so
                ;;
            sync-trace)
                preload=/opt/nova-kgsl-driver/libposix-sync-trace.so:/opt/nova-kgsl-driver/libsysv-sem-shim.so
                ;;
            *)
                echo "client_error=unknown_preload_profile:${NOVA_STEAM_PRELOAD_PROFILE}" >&2
                exit 2
                ;;
        esac
        echo "client_preload_profile=${NOVA_STEAM_PRELOAD_PROFILE:-full}" >> "$client_log"
    fi
    if [ "${NOVA_STEAM_DISABLE_PRELOAD:-0}" != "1" ] && [ -n "$preload" ]; then
        export LD_PRELOAD="$preload"
    fi

    if { [ "${NOVA_XWAYLAND_ALLOW_LOCAL:-0}" = "1" ] || [ -f /opt/nova-steam/allow-xwayland-local ]; } && [ -x /usr/bin/xhost ]; then
        xhost_log=/tmp/nova-steam-xhost.log
        xhost_target=${NOVA_XWAYLAND_XHOST_TARGET:-}
        if [ -z "$xhost_target" ]; then
            # The disposable Xwayland instance has no stable account database
            # for synthetic setpriv uids. Keep the opt-in allowance local to
            # UNIX clients instead of relying on a numeric SI username.
            xhost_target=+local:
        fi
        xhost_status=1
        xhost_attempt=0
        while [ "$xhost_attempt" -lt 20 ]; do
            : > "$xhost_log"
            env -u LD_PRELOAD DISPLAY=:0 /usr/bin/xhost "$xhost_target" >"$xhost_log" 2>&1
            if [ "$?" -eq 0 ] && ! grep -Eiq 'BadValue|unable|cannot|authorization' "$xhost_log"; then
                xhost_status=0
                break
            fi
            xhost_attempt=$((xhost_attempt + 1))
            sleep 0.1
        done
        echo "client_xhost_local_status=$xhost_status" >> "$client_log"
        echo "client_xhost_target=$xhost_target" >> "$client_log"
        echo "client_xhost_local_log=$xhost_log" >> "$client_log"
    fi
    if [ ! -x "$STEAM_EXECUTABLE" ]; then
        echo "client_started=fail" >> "$client_log"
        echo "client_error=missing_or_nonexecutable_executable" >> "$client_log"
        exit 1
    fi
    if [ -x /usr/bin/dbus-launch ]; then
        eval "$(run_as_steam /usr/bin/dbus-launch --sh-syntax --exit-with-session 2>/dev/null)" || true
    fi

    set -- $client_flags ${NOVA_STEAM_EXTRA_ARGS:-}
    run_as_steam /usr/bin/timeout "$CLIENT_TIMEOUT" "$STEAM_EXECUTABLE" "$@" \
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
