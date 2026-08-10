# Termux:X11 native ARM64 Steam OOBE Enter focus-guard result — 2026-08-09

Status: display and OOBE evidence passed, but the target Enter event was not
sent. The new focus guard inspected the wrong Android diagnostic output and
failed closed before injection. This is a harness-observability result, not an
input-path negative.

## Run identity and provenance

```text
run_id=termux-x11-20260809T171500Z-native-steam-oobe-enter-display-0
repo_commit=a74d8fd45cbf228a93e08fccf17fd854d094057e
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=405747d242d066ca544908f577c16cb73e600fcea185fbc469a10699a2a5b3a7
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206ae3efb4b017
x11_private_namespace_helper_sha256=f496898aa2cfd7002afa4e31d92f3943895fb1e286983577f72c94627a72f61e
x11_cleanup_helper_sha256=20399885fdfe65ba03c26ee2f1683ce84ec3e1f0e908488d91287bd4ec2e852c
x11_client_launcher_sha256=6ac146ef54286d832440e5e5c24b78673f938c7179cf5f7743d1d36f5cece
mount_private_helper_sha256=bd19b2ea6eb661f210dcbd5868ce54df678ffdf6ee43035995956789917f6520
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
bind_android_dev=1
client_namespace_mode=chroot-dev
steam_uid=501:20
steam_timeout=60s
capture_delay_seconds=8
input_mode=android-keyevent
input_keycode=66
input_key_name=KEYCODE_ENTER
```

The mandatory [Nova runtime harness lifecycle](../00-start-here/34-nova-runtime-harness-lifecycle.md)
was read immediately before the run. The run used fresh state and completed
the exact-scope cleanup sequence.

## What passed before the guard stopped the run

The new display session reached the same live Steam OOBE language selector:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
termux_x11_window=pass id=0x2400035
termux_x11_capture_delay=pass seconds=8
termux_x11_android_capture=pass sha256=afa40fe3d6abe39ea49a9fc7fe9d8e98586e9acdeef2f56ef967268766ea59c9
termux_x11_x11_capture=pass sha256=26010e0dda13091fcf3816cd8a92f7a1c087ba3d1eec06ae65f835d11191adee
```

The physical screenshot visibly showed `Welcome`, `Select a language`, and
the expanded language list with `English` at the top. The X11 window was the
same viewable Steam Big Picture/webhelper window. The client stayed alive for
the complete bound and produced complete final logs:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
client_stdout=506
client_stderr=5775
```

The before-input artifacts were identical copies of the initial capture:

```text
android-screenshot.png sha256=afa40fe3d6abe39ea49a9fc7fe9d8e98586e9acdeef2f56ef967268766ea59c9
android-screenshot-before-input.png sha256=afa40fe3d6abe39ea49a9fc7fe9d8e98586e9acdeef2f56ef967268766ea59c9
x11-window.ppm sha256=26010e0dda13091fcf3816cd8a92f7a1c087ba3d1eec06ae65f835d11191adee
x11-window-before-input.ppm sha256=26010e0dda13091fcf3816cd8a92f7a1c087ba3d1eec06ae65f835d11191adee
x11-tree.txt sha256=8776fac808fb735e4a9c2b14d3be49101a3aa7bd9966d1e6c9ea91fe9cdd6ec7
```

## Guard failure and root cause

The guard searched `dumpsys window windows` for `mCurrentFocus` or
`mFocusedApp`. This Android build lists the Termux:X11 window there but does
not emit those focus keys, so the check returned false and failed closed:

```text
termux_x11_activity_focus=unknown_or_missing
termux_x11_input_focus=fail
```

No `adb shell input keyevent 66` command was executed; the run directory has
no input-command artifact or after-input capture. A fresh Android input
diagnostic does expose the authoritative target:

```text
FocusedWindows:
    displayId=0, name='2c0d27a com.termux.x11/com.termux.x11.MainActivity'
```

The next harness revision therefore reads `dumpsys input` for the focus gate,
while retaining the window dump as supplementary state. It must continue to
fail closed if the focused target is neither Termux:X11 nor the known settings
overlay.

## Cleanup

The run exited cleanly after the guard failure:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Decision

This run neither accepts nor rejects Android-to-X11 keyboard input. The
authoritative focus-source repair is committed with the next retry contract.
The retry repeats the same OOBE profile and sends the single Enter event only
after `dumpsys input` names `com.termux.x11` as the focused window.
