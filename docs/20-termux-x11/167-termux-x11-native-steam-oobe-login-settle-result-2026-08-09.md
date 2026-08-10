# Termux:X11 native ARM64 Steam OOBE login-settle result — 2026-08-09

Status: repeatable X11/Android presentation and input pass, but no QR/login
surface after a 12-second settle. The run confirms that the remaining wait is
not explained by the physical display, X11 forwarding, or basic chroot network
reachability.

## Run identity and provenance

```text
run_id=termux-x11-20260809T190000Z-native-steam-oobe-login-settle-display-0
repo_commit=8ae8c69e4e3f47aa602965fca0d7960939e9896e
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
capture_delay_seconds=8
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
input_key_name=KEYCODE_ENTER
input_delay_seconds=1
input_after_delay_seconds=12
```

The mandatory [Nova runtime harness lifecycle](../00-start-here/34-nova-runtime-harness-lifecycle.md)
was read immediately before launch. The run used a fresh runtime identity and
passed exact-scope teardown.

## Presentation and input result

All three events passed the focus, injection, same-window, and capture gates:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
termux_x11_window=pass id=0x2400035
termux_x11_capture_delay=pass seconds=8
termux_x11_input_step=pass step=1 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=1 id=0x2400035
termux_x11_input_focus_after=pass step=1
termux_x11_input_step=pass step=2 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=2 id=0x2400035
termux_x11_input_focus_after=pass step=2
termux_x11_input_step=pass step=3 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=3 id=0x2400035
termux_x11_input_focus_after=pass step=3
termux_x11_input_sequence=pass events=3
```

The final physical Android frame and paired X11 frame both still show the
animated Steam logo with `Waiting for network...`; neither shows the QR/login
surface. The Android frame also contains the expected rooted-harness status
bar and Termux extra-key bar. The Steam content agrees between the two capture
paths.

Frame hashes:

```text
android_initial=d167898367e35fb91a74cb4e655627be2626795aa1e391d4e42c60fd654875f8
android_step1_after=f8da4043b7b174df8378f2f6c99c3236b2ca6f03a66b03389805d5ffa264a9ff
android_step2_after=c023719e7f8023e3e73024b4ed2ccf3c1f31cee0708bd68041ddfb68e0cb0486
android_step3_after=809f23608396b6c5276b239631e5765f32f95a083f4cf65d5134cf5593a0d52c
x11_initial=07d6208cd0ab884b76368dfb6db81feef4ebee1b44c1532b370f21aa59068033
x11_step1_after=e3aae498a472c3211bf91bc198ffc2968fd040fec30944b2ca03510665e745ef
x11_step2_after=741aa84ea442789af05dac3f9460d7d3bf336bd0ad961da94552b8c7a9e985cd
x11_step3_after=5eb4bee9f4446a75082a845c1318fb233cd6152eb4dc3810e062b80660f37960
input_sequence=4c4bcd0feb1dd442286a9e71895044c31a5ccc4bed183d41ca0ed7ca542e6d88
```

## Fresh Steam state evidence

The run-correlated logs show that the local Steam UI transport and the Steam
connectivity probe are working:

```text
[2026-08-09 17:21:06] Connectivity test (23.215.0.12:80): OK!
[2026-08-09 17:21:06] Connectivity test: result=Connected
[2026-08-09 17:21:07] CWebSocketConnection (steamUI): connection ready
[2026-08-09 17:21:07] CWebSocketConnection (clientdll): connection ready
[2026-08-09 17:21:07] WebUITransportStore: Connection status: connected
[2026-08-09 17:21:09] Login: OnLoginStateChange  1 1 0 0
[2026-08-09 17:21:08] [ None ] SetLoginState: WaitingForCredentials - OK
```

The harness stopped the direct client at its declared 60-second bound:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
```

The client then began its background update check immediately before shutdown;
its `Download failed: http error 0` line is therefore timeout-correlated, not
evidence that the chroot lacks network access. Independent read-only checks
after teardown resolved `client-update.steamstatic.com` in the rootfs and
received `HTTP/1.1 200 OK` from the rootfs `curl`. Android reported a validated
Wi-Fi network with route `0.0.0.0/0 -> 192.168.0.1`.

## Cleanup and artifacts

```text
steam_client_log_sha256=db132cc2e068b1e15e7db008788594a063eaf3acf1ec4052cc6b140ab6154c79
steam_client_stdout_sha256=0d917fc0c257cbd766a095177db99024958915d8c89069f2bff4919cce14ac31
steam_client_stderr_sha256=474c8e9c212f10cd930dde3fc1c46ee74d65b0af7519654ba73673b9486fbc00
namespace_cleanup=pass
nova_x11_cleanup=pass
nova_runtime_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
```

## Decision

The 12-second delay did not change the final visual state, while Steam reached
its credentials state and passed its connectivity test. The direct Termux:X11
path has therefore cleared the Android/X11 rendering and input blockers. The
next experiment should keep the same three events and presentation stack but
let the Steam process live substantially longer, so a slow or deferred login
surface can be distinguished from a state machine that remains indefinitely
at `WaitingForCredentials`.
