# Termux:X11 network inventory client-selection result — 2026-08-09

Status: profile-selection failure; no networking or Steam result was accepted.

## Run identity

```text
run_id=termux-x11-20260809T175841Z-network-inventory-1
repo_commit=1b5065e
adb_serial=675a2365
device=Retroid Pocket Nova
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
bind_android_dev=1
client_namespace_mode=chroot-dev
x11_window_wait_seconds=10
network_observer=1
```

The retry fixed the one-second X11 window discovery bound and found a mapped
window, but the invocation did not select the native Steam client. Because
`NOVA_X11_ANIMATE` was omitted, the existing deploy harness correctly used its
documented synthetic default:

```text
client=android/nova-lab/build/nova-x11-animate
window_name=Nova animated Xwayland Gamescope probe
```

The fresh X11 tree and client artifacts confirm that this was the synthetic
control, not a Steam launch. The Steam logs were empty and the run never
started the network observer.

## Observed control result

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
termux_x11_window=pass id=0x200001
nova_x11_capture=failed id=0x200001 reason=xgetimage error_code=8 depth=24 visual=0x21
termux_x11_capture_status=1
```

The depth-24 `XGetImage`/`BadMatch` result is already a known observational
limitation of this synthetic Termux:X11 capture profile. It is not a
networking result, and the run did not reach the Android screenshot or input
gates because `allow_x11_capture_failure` was not enabled.

## Cleanup

The exact-scope cleanup contract passed:

```text
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
termux_x11_post_stop=pass
nova_runtime_cleanup=pass
```

## Next action

Repeat the inventory with the native client selected explicitly:

```text
NOVA_X11_ANIMATE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/device/nova-termux-x11-steam-client.sh
NOVA_TERMUX_X11_WINDOW_NAME=
NOVA_TERMUX_X11_WINDOW_WAIT_SECONDS=25
NOVA_TERMUX_X11_ALLOW_X11_CAPTURE_FAILURE=1
```

Keep the observer, Steam flags, namespace, input sequence, APK, and renderer
unchanged. This preserves the already documented native-Steam profile and
keeps the known X11-side readback limitation observational while the Android
SurfaceView remains the presentation gate.
