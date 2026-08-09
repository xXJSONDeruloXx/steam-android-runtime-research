# Termux:X11 native ARM64 Steam OOBE timezone persistence result — 2026-08-09

Status: positive input result with a persistence boundary. The focused Enter
event again advanced the live Steam OOBE from language selection to timezone,
but a fresh bounded relaunch started at language selection again. The input
path works; the current one-event-per-run harness cannot carry OOBE progress
through a sequence of fresh launches.

## Run identity and provenance

```text
run_id=termux-x11-20260809T174500Z-native-steam-oobe-timezone-enter-display-0
repo_commit=d3f2412fc24481f2e0193e284f77f5edd0eb4394
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

The mandatory [Nova runtime harness lifecycle](34-nova-runtime-harness-lifecycle.md)
was read immediately before the run. Exact-scope cleanup passed on exit.

## Input and presentation result

The run repeated the validated focused keyevent path:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
termux_x11_window=pass id=0x2400035
termux_x11_capture_delay=pass seconds=8
termux_x11_android_capture=pass sha256=1f9a9560e96d94cc353a4b626c0b3c13dbc2f9ee426edeffe152c708ca711532
termux_x11_x11_capture=pass sha256=57f645a29aa64bc7d6c240e4425c585334329c9e44aef85124729fcf6a89fb05
termux_x11_input=pass keycode=66 name=KEYCODE_ENTER
termux_x11_window_after_input=pass id=0x2400035
termux_x11_x11_capture_after_input=pass sha256=599ca5f14d6a72e6c96bdb33834fe12db027421b311834d3b05f6d0df025231b
termux_x11_input_focus_after=pass
termux_x11_android_capture_after_input=pass sha256=74ff013409c8bd1601843dcb0985fe2c4fe1190ab41ade505db0d8bb17655a97
termux_x11_input_android_screen_changed=pass
termux_x11_input_x11_screen_changed=pass
```

The before screenshot was again the language selector; the after screenshot
was `Choose your timezone` with `Pacific Standard Time` highlighted. The
paired X11 frame showed the same transition. The Android capture again
included only the transient rooted-harness superuser toast in addition to the
Steam content.

## Persistence observation

Despite the previous run ending on the timezone page, this fresh run's first
capture was the language page. Therefore the visible OOBE state is not a
reliable cross-run checkpoint at this stage. Treating a new launch as if it
resumed the previous screen would violate the fresh-run evidence contract.

The native client itself remained alive for the full bound:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
client_stdout=506
client_stderr=5967
```

## Cleanup

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Decision and next step

This is not a rejection of the X11 input route. It establishes that OOBE
progress must be advanced within one live Steam/X11 session. The next
experiment adds a committed sequence mode and sends two explicitly recorded
Enter events in one fresh session: language-to-timezone, then timezone-to-the
next OOBE stage.
