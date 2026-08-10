# Termux:X11 native ARM64 Steam result — 2026-08-09

Status: failed at Steam process initialization; Termux:X11 server lifecycle
and cleanup passed. No Steam window or Android screenshot was produced.

## Run identity and provenance

```text
run_id=termux-x11-20260809T161500Z-native-steam-direct-display-0
repo_commit=6fcd9f91db25773c470105366782d34a24fa52d6
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=8276eb2034302b20321be5887e23c3fb9299dca30c6c434d9bbf2d9871fad3a4
nova_x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

## Observed boundary

The Termux:X11 server came up and the Android Activity established the same
fresh XCB/EGL/shared-buffer path as the synthetic pass. The Steam launcher
then recorded:

```text
client_runtime_owner_status=pass
client_network_api_compat_status=0
client_xhost_local_status=0
client_started=pass
client_installed=pass
client_status=1
client_end=present
```

Steam did not create a viewable depth-1 X11 child during the 25-second window
poll. The only X11 tree was the viewable root:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>"
nova_x11_tree=pass root=0x511
```

The decisive fresh Steam stderr was:

```text
src/tier0/platform_posix.cpp (841) : s_dev_urandom_fd >= 0
src/tier0/platform_posix.cpp (841) : Fatal assert; application exiting
```

This is a rootfs device-namespace failure before Steam can reach X11 window
creation, CEF, SteamUI, OOBE, or login. The current rootfs inspection found:

```text
/data/local/tmp/nova-holo-rootfs/dev/urandom: absent
/data/local/tmp/nova-holo-rootfs/dev/random: absent
/data/local/tmp/nova-holo-rootfs/dev/null: regular file, not a character device
/dev/urandom on Android: character device 1,9
```

The run metadata selected the default synthetic window name despite the shell
invocation supplying an empty `NOVA_TERMUX_X11_WINDOW_NAME`; the harness uses
the `:-` defaulting form. That is a separate test-harness defect and will be
corrected with the device namespace repair. It cannot explain this result:
the Steam process had already exited with the fresh `s_dev_urandom_fd` fatal
assertion, and the X11 tree remained root-only.

## Cleanup

The exit trap and independent runtime cleanup passed:

```text
pre_cleanup_server_pids=30933,
pre_cleanup_client_pids=
client_matching=1 phase=runtime
namespace_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_x11_cleanup=pass
termux_x11_post_stop=pass
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

The run-specific client log, stdout, and stderr were pulled into the ignored
run directory. Their SHA-256 values are:

```text
steam-client.log=a9b8f0e4ccc7be877b6314ed0a64d7c965130ba73abb80a543794988d7adc915
steam-client.stdout=e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa
steam-client.stderr=ef1f169f15cf5b55bd29254ee2e63b67627670e3ed059a6d3a94dfa0657d3787
```

## Next experiment

Repair only the disposable rootfs device namespace: provide correct `null`,
`zero`, `random`, and `urandom` character devices before the next direct
Steam launch, and fix empty-window-name handling. Keep the same Termux:X11
server, Steam flags, software renderer, and cleanup contract. Do not change
Gamescope or the AHardwareBuffer path in response to this failure.
