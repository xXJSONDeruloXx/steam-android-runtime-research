# Termux:X11 private session-bus startup-failure result — 2026-08-09

Status: setup failure; no Steam networking conclusion accepted.

## Run identity and provenance

```text
run_id=termux-x11-20260809T181632Z-network-session-bus-0
repo_commit=0eb11f086b193637d89256a146afe29bafb0ddaf
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
source_tree=/Users/kurt/Developer/steam-android-runtime-research
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=7e9673cc4ea90dea3f9c50478565f644c3800f486a81d03504e6989bc80f6475
network_observer=enabled_but_not_started
dbus_session=1
steam_uid=501:20
steam_timeout_seconds=75
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
window_wait_seconds=25
```

The run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T181632Z-network-session-bus-0/
```

## Result

The Termux:X11 server started and its socket passed the preflight gate. The
native client was launched with `NOVA_TERMUX_X11_DBUS_SESSION=1`, but the
private bus never became ready, so the client exited before starting Steam.
The harness consequently could not discover an X11 Steam window after 25
seconds and did not start the network observer.

The client log recorded:

```text
client_dbus_session=enabled
client_dbus_session_config=/usr/share/dbus-1/session.conf
client_dbus_session_socket=/tmp/nova-steam-runtime/dbus-session-23218/bus
client_dbus_session_status=fail reason=socket_not_ready
dbus[23980]: Unable to set up transient service directory: XDG_RUNTIME_DIR subdirectory "/tmp/nova-steam-runtime/dbus-1" is owned by uid 0, not our uid 501
dbus[23980]: Could not get password database information for UID of current process: Looking up user ID 501: not found
dbus[23980]: Failed to start message bus: Memory allocation failure in message bus
dbus_session_cleanup=pass path=/tmp/nova-steam-runtime/dbus-session-23218
```

The final `Memory allocation failure` is downstream of the missing runtime
ownership/user lookup and is not interpreted as a device memory result. There
was no fresh Steam process, UI, QR surface, DNS request, or external Steam
socket in this run; the result must not be compared with the successful
network inventory as a networking outcome.

## Cleanup

The exact-scope teardown passed despite the early client exit:

```text
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
termux_x11_post_stop=pass
nova_runtime_cleanup=pass
```

The launcher also recorded cleanup of its exact private session directory.
No network observer artifact was expected because the observer starts only
after a viewable native Steam window has been captured.

## Next action

Inspect the rootfs D-Bus prerequisites without changing the Android network or
Steam UI: the passwd database for UID 501, the XDG runtime directory and its
`dbus-1` ownership, and the installed `dbus-daemon` configuration. Then make
the smallest run-scoped repair, commit and push it, and rerun this same
session-bus experiment with a fresh identity. Do not call this a session-bus
negative until the daemon actually reaches a ready socket and Steam has run.
