# Termux:X11 native ARM64 Steam OOBE network result — 2026-08-09

Status: major positive result. A single fresh Steam/X11 session accepted two
focused Android Enter events and advanced the visible OOBE through two pages:
language selection → timezone selection → network selection. The final
`Choose your network` page is visible on both the physical Nova screen and the
paired X11 capture, with `Continue with Android host network` highlighted.

## Run identity and provenance

```text
run_id=termux-x11-20260809T180000Z-native-steam-oobe-two-enter-display-0
repo_commit=75cec19d3312c34e3f3813a86f94654bea3eb2fb
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
input_mode=android-keyevent-sequence
input_keycodes=66,66
input_key_name=KEYCODE_ENTER
input_delay_seconds=1
input_after_delay_seconds=4
```

The mandatory [Nova runtime harness lifecycle](34-nova-runtime-harness-lifecycle.md)
was read immediately before the run. This was one fresh session; no OOBE
screen or log from a previous run was used as readiness evidence.

## Sequence and presentation evidence

The server, window, and both input steps passed:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
termux_x11_window=pass id=0x2400035
termux_x11_capture_delay=pass seconds=8
termux_x11_android_capture=pass sha256=fbfcbfcb6e1c1da0f8dc7116d4fe1eda66ef6811d6c46b3c38ada49f854dc835
termux_x11_x11_capture=pass sha256=f3be3e80d1d973ab95c39894b104d9b504817412e8b4aecb518be0ba26b5f1e5
termux_x11_input_step=pass step=1 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=1 id=0x2400035
termux_x11_x11_capture_step_after_input=pass step=1 sha256=c0ba23eed91261fef1299103ed590a4a80e50608d27cfe0554ae49b01fddce86
termux_x11_input_focus_after=pass step=1
termux_x11_android_capture_step_after_input=pass step=1 sha256=b8a4b9dec17d52d8d805d6029c199a6dc7ab56b9380d56127ae6eb6b66058e71
termux_x11_input_android_screen_changed=pass step=1
termux_x11_input_x11_screen_changed=pass step=1
termux_x11_input_step=pass step=2 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=2 id=0x2400035
termux_x11_x11_capture_step_after_input=pass step=2 sha256=e32908f24ea6f49768bf1be1b9d63d59ecbbe1ceaa286a725c9f82dee16bd68d
termux_x11_input_focus_after=pass step=2
termux_x11_android_capture_step_after_input=pass step=2 sha256=65269a303d50df8217a088d64ed5a8875b9d17bce3e2c866fd245de93ce830f4
termux_x11_input_android_screen_changed=pass step=2
termux_x11_input_x11_screen_changed=pass step=2
termux_x11_input_sequence=pass events=2
```

The sequence log recorded two successful commands, each after an independent
Termux:X11 focus check:

```text
input_mode=android-keyevent-sequence
input_keycodes=66,66
input_step=1
input_keycode=66
input_focus=pass package=com.termux.x11
input_command=adb shell input keyevent 66
input_exit_status=0 step=1
input_step=2
input_keycode=66
input_focus=pass package=com.termux.x11
input_command=adb shell input keyevent 66
input_exit_status=0 step=2
```

The step-1 before frame was the fresh language page. Step 1 produced
`Choose your timezone` with `Pacific Standard Time` highlighted. Step 2
produced `Choose your network` with `Continue with Android host network`
highlighted. The X11 and Android images agreed at each transition; the
Android screenshots include only the transient rooted-harness superuser toast.

```text
android-initial sha256=fbfcbfcb6e1c1da0f8dc7116d4fe1eda66ef6811d6c46b3c38ada49f854dc835
android-step-1 sha256=b8a4b9dec17d52d8d805d6029c199a6dc7ab56b9380d56127ae6eb6b66058e71
android-step-2 sha256=65269a303d50df8217a088d64ed5a8875b9d17bce3e2c866fd245de93ce830f4
x11-initial sha256=f3be3e80d1d973ab95c39894b104d9b504817412e8b4aecb518be0ba26b5f1e5
x11-step-1 sha256=c0ba23eed91261fef1299103ed590a4a80e50608d27cfe0554ae49b01fddce86
x11-step-2 sha256=e32908f24ea6f49768bf1be1b9d63d59ecbbe1ceaa286a725c9f82dee16bd68d
input-sequence-log sha256=ba7ef2e93d57ea297c851c46caf923faee1e7a11b570c45cad5554e80367e385
```

The X11 tree kept the same viewable `0x2400035` Steam Big Picture/webhelper
window through both steps, including the nested viewable webhelper surfaces.

## Client and cleanup evidence

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
client_stdout=506
client_stderr=5952
```

Cleanup passed without manual intervention:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Decision and next step

This establishes a credible in-session direct-X11 OOBE navigation path through
the language, timezone, and network gates. The next experiment repeats the
first two Enter events inside one fresh session and adds a third Enter to
select `Continue with Android host network`. The acceptance target is the
following login/OOBE page, ideally the QR login view.
