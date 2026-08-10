# Termux:X11 native ARM64 Steam cleanup-control result — 2026-08-09

Status: the corrected native-Steam control passed the repaired evidence and
cleanup contract. Steam stayed alive through the full 60-second timeout and
created a viewable Big Picture/webhelper window, but both X11 and physical
Android pixels were solid white. No OOBE, login, or QR pixels were visible.

## Run identity and provenance

```text
run_id=termux-x11-20260809T164200Z-native-steam-cleanup-control-display-0
repo_commit=92459a378f534a95f7657355f47722f572128125
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=d21fce0d327d146295142612670028f96977400d003c006ac72ee106397f95df
x11_private_namespace_helper_sha256=f496898aa2cfd7002afa4e31d92f3943895fb1e286983577f72c94627a72f61e
x11_cleanup_helper_sha256=20399885fdfe65ba03c26ee2f1683ce84ec3e1f0e908488d91287bd4ec2e852c
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

## Native Steam result

The final client log was captured after the host-side launcher wait, proving
that the result is complete rather than an early teardown snapshot:

```text
mount_private=pass path=/
client_runtime_owner_status=pass
client_network_api_compat_status=0
client_xhost_local_status=0
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
client_stdout=506
client_stderr=5832
client_end 1786293859
```

The timeout is meaningful here: Steam remained alive for the complete bound,
and the launcher then performed its normal timeout shutdown. This corrects the
previous procfs result's incomplete early `client_status=1` snapshot.

The X11 tree contained the expected viewable Steam Big Picture and nested
`steamwebhelper` surfaces:

```text
nova_x11_window id=0x1c0003b parent=0x511 depth=1 map_state=viewable x=0 y=0 width=1280 height=800 name="Steam Big Picture Mode" res_name="steamwebhelper" res_class="steam"
nova_x11_window id=0xe00006 parent=0x1c0003b depth=2 map_state=viewable x=0 y=0 width=1280 height=800
nova_x11_window id=0xe00008 parent=0xe00006 depth=3 map_state=viewable x=0 y=0 width=1280 height=800
nova_x11_tree=pass root=0x511
nova_x11_capture=pass id=0x1c0003b width=1280 height=800
```

The Android screenshot and X11 PPM were visually solid white content with
only the Android status/extra-key bars and X cursor visible. There was no Steam
branding, OOBE control, login form, or QR code.

```text
android-screenshot.png sha256=8b9567fe8f5803b91bfafa5d7d4e09694ef187d6186bee38b14c372d4eac18ed
x11-window.ppm sha256=2097d8f3aa89cb4083d5414e2636bbd9cf88d6a261844a2d8b9a947554376311
x11-tree.txt sha256=0a3e63928a901701fad3e5e0fbfcb19b5bdbdc967bb496d905eb4b64a17dddab
x11-capture.txt sha256=8942c5d28ce5a65c0af324a1b850103ed6a50afa99a1b4602cff91b3da66e869
steam-client.log sha256=1a787faec24a0297debe30bc5937c92c90ee6cd80605d46652c0f75fc68c332a
steam-client.stdout sha256=0d917fc0c257cbd766a095177db99024958915d8c89069f2bff4919cce14ac31
steam-client.stderr sha256=ca1ec0e1fda396848889742ebb5261aef4b917caad5ee66d48341461790e62ca
```

## UI and renderer evidence

The fresh run's Steam UI log state reached the application logic boundary:

```text
[2026-08-09 16:43:21] SteamUI: INFO: CWebSocketConnection (steamUI): connection ready
[2026-08-09 16:43:21] SteamUI: INFO: CWebSocketConnection (clientdll): connection ready
[2026-08-09 16:43:21] SteamUI: INFO: Login: OnLoginStateChange  0 1 0 0
[2026-08-09 16:43:22] SteamUI: INFO: OOBE Store: keyboards 1
```

The corresponding `steamwebhelper.log` reports a CEF assertion and dump at
startup, but the web UI then connects and remains alive:

```text
src/webhelper/html_chrome.cpp (624) : CefCrashReportingEnabled()
DevTools listening on ws://127.0.0.1:8080/devtools/browser/...
```

Its GPU report identifies the active renderer as software ANGLE/softpipe over
X11, with GPU compositing enabled but no allocated GPU buffer formats:

```text
GPU0 = ANGLE (Mesa, softpipe, OpenGL 3.3 (Core Profile) Mesa 25.2.7-arch1.1)
Ozone platform = x11
gpu_compositing = enabled
opengl = enabled_on
vulkan = disabled_off
RGBA_8888 = Software only
BGRA_8888 = Software only
```

These logs make CEF/Chromium surface composition the leading hypothesis for
the white pixels. They do not prove that the CEF assertion is the sole cause;
the next experiment must change one CEF rendering flag at a time.

## Cleanup

The repaired helper completed without manual intervention:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Decision and next step

The Termux:X11 route is now a reliable native Steam process/window/presentation
path, and the evidence harness is reliable enough to trust a 60-second run.
The blocker is no longer rootfs `/dev`, `/dev/shm`, `/proc`, X11 mapping, or
Android SurfaceView forwarding. Keep the AHB/Gamescope line separate.

The next predeclared UI experiment should add the prior-art CEF flag
`-cef-disable-gpu` while keeping every other variable fixed. If the surface
remains white, follow with separate `-cef-in-process-gpu` and
`-cef-disable-gpu-compositing` experiments rather than combining them.
