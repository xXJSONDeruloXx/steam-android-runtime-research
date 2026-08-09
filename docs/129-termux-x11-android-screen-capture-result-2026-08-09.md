# Termux:X11 Android screen-capture result — 2026-08-09

Status: Android-side forwarding pass; Steam/OOBE was not attempted.

## Run identity and provenance

```text
run_id=termux-x11-20260809T160500Z-android-screen-capture-display-0
repo_commit=6ee50674f6d106c05081a043f498365eec73109b
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
presentation=official Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
termux_x11_commit=d8013ac5d174bb16120f915c10a7255948c59c17
nova_x11_animate_sha256=884853cdc47c0d10a644153404fcd25e155b8784e24903f3ced568649b10bc04
nova_x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
allow_x11_capture_failure=1
```

## Result

The run passed the physical Android-screen gate:

```text
preflight: nova_x11_cleanup=pass client_matching=0 phase=preflight
server: termux_x11_server=pass display=:0 socket=.../tmp/.X11-unix/X0
window: termux_x11_window=pass id=0x200001
android_capture: termux_x11_android_capture=pass sha256=a4f05689a95e44e1966a2a00f83052da13c82df7c6d1275f628065e51de2fd6d
teardown: termux_x11_post_stop=pass
nova_runtime_cleanup=pass
```

The captured image is
`android/nova-lab/build/manual-runs/termux-x11-20260809T160500Z-android-screen-capture-display-0/android-screenshot.png`
with SHA-256
`a4f05689a95e44e1966a2a00f83052da13c82df7c6d1275f628065e51de2fd6d`.
Visual inspection shows the expected teal Termux:X11 surface, the synthetic
client's white animated square, the X cursor, and the Termux:X11 extra-key
bar on the physical 1280x960 Android display. This is the first run in this
track that proves X11 client pixels reached the Android screenshot artifact.

The X11-side capture helper remains an observational failure:

```text
nova_x11_capture=failed id=0x200001 reason=xgetimage error_code=8 depth=24 visual=0x21
termux_x11_capture_status=1
```

That failure did not invalidate the Android screenshot because this run used
the explicitly named `NOVA_TERMUX_X11_ALLOW_X11_CAPTURE_FAILURE=1` profile. It
does mean there is no independent X11 PPM for pixel correlation yet.

## Runtime evidence

The X11 tree reported a viewable root and a viewable mapped child:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x200001 parent=0x511 depth=1 map_state=viewable x=0 y=0 width=1280 height=720 name="Nova animated Xwayland Gamescope probe"
nova_x11_tree=pass root=0x511
```

Fresh Android logcat evidence from the same run records the Termux:X11 server
commit, the rootfs `TMPDIR`, a new X client connection, successful XCB
connection extraction, and shared Android buffers at 1280x1024, 1280x864, and
1280x714. The window dump records
`com.termux.x11/com.termux.x11.MainActivity` with a drawn, ready surface. The
harness focus matcher returned `unknown_or_missing`; a superuser toast was
also present in the screenshot, so future input tests must explicitly dismiss
or account for that overlay before attributing input behavior.

## Cleanup

The exit trap found and removed the server, removed the exact staged paths,
stopped the Termux:X11 Activity, and passed the independent post-stop check:

```text
pre_cleanup_server_pids=29468,
pre_cleanup_client_pids=
client_matching=1 phase=runtime
namespace_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_x11_cleanup=pass
termux_x11_post_stop=pass
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Interpretation and next step

This establishes the forwarding layer needed for the new branch:

```text
native X11 client -> Termux:X11 X socket -> Android XCB/EGL/shared buffers -> physical Nova screenshot
```

It does not yet establish Steam rendering, Steam input, native ARM64 Steam
startup, OOBE progression, or QR login. The next bounded experiment should
replace the synthetic client with the smallest rootfs-native X11 application
that can present a real window while retaining the same Android capture and
cleanup gates. After that, bring up the Steam runtime in stages and require a
fresh screenshot plus corresponding Steam/X11 evidence at each stage.
