# Termux:X11 native ARM64 Steam procfs result — 2026-08-09

Status: the private `/dev`, `/dev/shm`, and `/proc` setup passed. Native ARM64
Steam reached a viewable Big Picture and `steamwebhelper` X11 window, and both
X11 and physical Android capture passed. The captured pixels were solid white;
no OOBE, login, or QR view was visible.

## Run identity and provenance

```text
run_id=termux-x11-20260809T193000Z-native-steam-procfs-display-0
repo_commit=bbea6d2b9f23afc97c977df0b08a4bd8d8712b5b
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=d21fce0d327d146295142612670028f96977400d003c006ac72ee106397f95df
x11_private_namespace_helper_sha256=f496898aa2cfd7002afa4e31d92f3943895fb1e286983577f72c94627a72f61e
x11_client_launcher_sha256=6ac146ef54286d832440e5e5c24b78673f938c7179cf5f7743d57d1d36f5cece
mount_private_helper_sha256=bd19b2ea6eb661f210dcbd5868ce54df678ffdf6ee43035995956789917f6520
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
bind_android_dev=1
client_namespace_mode=chroot-dev
steam_uid=501:20
steam_timeout=60s
x11_window_wait_seconds=25
```

## Steam and X11 result

Fresh client logging reached the Steam UI path:

```text
mount_private=pass path=/
client_runtime_owner_status=pass
client_network_api_compat_status=0
client_xhost_local_status=0
client_started=pass
client_status=1
client_installed=pass
client_end 1786292932
```

The X11 tree contained a viewable Steam Big Picture window and nested
`steamwebhelper` windows:

```text
nova_x11_window id=0x180003b parent=0x511 depth=1 map_state=viewable x=0 y=0 width=1280 height=800 name="Steam Big Picture Mode" res_name="steamwebhelper" res_class="steam"
nova_x11_window id=0xe00006 parent=0x180003b depth=2 map_state=viewable x=0 y=0 width=1280 height=800
nova_x11_window id=0xe00008 parent=0xe00006 depth=3 map_state=viewable x=0 y=0 width=1280 height=800
nova_x11_tree=pass root=0x511
```

The X11 capture passed for window `0x180003b` at 1280x800, and the Android
screen capture passed. Both images were visually uniform white content. The
Android image still showed only the system status bar, Termux:X11 extra-key
bar, and the X cursor; it showed no Steam text, OOBE controls, login form, or
QR code.

Run artifact hashes:

```text
android-screenshot.png sha256=6dedd1a94052343737633bd57bf57d6d5029c9fc652d5b58a8dc183cfd5d2a4b
x11-window.ppm sha256=2097d8f3aa89cb4083d5414e2636bbd9cf88d6a261844a2d8b9a947554376311
x11-tree.txt sha256=a211aa0c3fad205edaea221fb924a89cbe7c8904ec3bf3934640e97d174b2517
x11-capture.txt sha256=25c827d686602decdd5fdef10296bb633210b3e9737b10762ba647f792fcc365
steam-client.log sha256=d0a57bd12d2d09cef351fe0061e6366ac539f9a905e67431ddb814e1431a897a
steam-client.stdout sha256=0d917fc0c257cbd766a095177db99024958915d8c89069f2bff4919cce14ac31
steam-client.stderr sha256=12fd9356222eb1b8eee100b22bc4a2f8cac29321e926418d133e9c80793056fe
```

Steam's fresh stderr still reports no Vulkan physical device, unavailable
`XRRGetOutputInfo`, missing `xwininfo`, and absent system/session services.
The Steam UI logs nevertheless show the web UI transport becoming connected,
`Login: OnLoginStateChange 0 1 0 0`, and `OOBE Store: keyboards 1`. The
`steamwebhelper.log` also records a CEF crash-reporting assertion and a dump
upload immediately after startup. This makes a CEF/software-compositor
failure a stronger next hypothesis than another rootfs mount failure, but
does not prove which missing service or renderer condition causes the white
surface.

## Cleanup and harness note

The recorded cleanup markers passed:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

During teardown, the cleanup helper raced a vanished recorded server PID and
left a `tr` child spinning while reading that procfs command line. Only that
run-specific child was terminated; the helper then completed and emitted the
pass markers above. This is a harness robustness defect to repair and test as
its own committed experiment before relying on long-lived sessions.

## Decision and next step

The Termux:X11 forwarding path is now proven through native Steam window
creation and Android presentation. `/dev`, `/dev/shm`, and `/proc` are not
the remaining blocker for window creation. Keep this branch and preserve the
AHB/Gamescope line separately.

Before another UI hypothesis, repair the cleanup procfs race and make the
client log capture wait for the launcher result. Then rerun the same profile
with one CEF/software-renderer variable at a time, starting with the
documented CEF crash/blank-surface boundary. Do not claim OOBE or QR until
the physical screenshot contains the actual Steam UI.
