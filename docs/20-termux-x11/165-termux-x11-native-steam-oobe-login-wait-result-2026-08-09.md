# Termux:X11 native ARM64 Steam OOBE login-wait result — 2026-08-09

Status: major positive backend result with a visual settle boundary. The
third focused Enter selected `Continue with Android host network`. Steam then
completed OOBE Stage 2 and entered its login/credentials state, while the
four-second post-input capture still showed the intermediate `Waiting for
network...` screen on both physical Android and X11.

## Run identity and provenance

```text
run_id=termux-x11-20260809T183000Z-native-steam-oobe-network-select-display-0
repo_commit=8d61fbe10574ed4c5c1668ce1a6197cf154c08ca
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
input_keycodes=66,66,66
input_key_name=KEYCODE_ENTER
input_delay_seconds=1
input_after_delay_seconds=4
```

The mandatory [Nova runtime harness lifecycle](../00-start-here/34-nova-runtime-harness-lifecycle.md)
was read immediately before the run. The session used fresh state and passed
exact-scope teardown.

## Three-step input and frame result

All three events were focused, delivered, and captured against the same
viewable Steam window:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
termux_x11_window=pass id=0x2600035
termux_x11_capture_delay=pass seconds=8
termux_x11_android_capture=pass sha256=c3fb16d8deae875b0b9b2b5d7eb435763fee19072b50bad59c761f59fdff11c8
termux_x11_x11_capture=pass sha256=c44dc26519e3344d10bbf486ab71c8f853e6148be814c44dfbafdbeb91f97bbb
termux_x11_input_step=pass step=1 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=1 id=0x2600035
termux_x11_x11_capture_step_after_input=pass step=1 sha256=2d79906df97d416cf44cb850f2e7dd7093eb9939d9048cac54bcd93ca2c3f543
termux_x11_input_focus_after=pass step=1
termux_x11_android_capture_step_after_input=pass step=1 sha256=fd4882e0ec9854a3d33ca625921301c9863bae866b4bcacac2c29f905cec4c86
termux_x11_input_step=pass step=2 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=2 id=0x2600035
termux_x11_x11_capture_step_after_input=pass step=2 sha256=0584849786204bae23836a640f937a57d1788de760b971208ecabefffe72cc0a
termux_x11_input_focus_after=pass step=2
termux_x11_android_capture_step_after_input=pass step=2 sha256=a72356d559206b5f230c0ae49facc58d05d0934fd62fc724339880c936bbd211
termux_x11_input_step=pass step=3 keycode=66 name=KEYCODE_ENTER
termux_x11_window_step_after_input=pass step=3 id=0x2600035
termux_x11_x11_capture_step_after_input=pass step=3 sha256=77dc60d510741157b90bee4b664e960b37d19e663e3bc2577d37fa095612d7ab
termux_x11_input_focus_after=pass step=3
termux_x11_android_capture_step_after_input=pass step=3 sha256=b6cb856d923b617ccccf307f110aaa459c7d34aa20c1a71c659624d893661732
termux_x11_input_sequence=pass events=3
```

The visible progression was:

1. fresh language selector;
2. timezone selector after Enter 1;
3. network selector with `Continue with Android host network` highlighted
   after Enter 2;
4. black Steam screen reading `Waiting for network...` after Enter 3.

The physical Android and X11 frames agreed at every step. The Android frame
contains the rooted-harness superuser toast in some captures; the Steam content
and the X11 frame remain the authoritative comparison.

## Fresh Steam login/OOBE state evidence

The same-run persistent Steam UI log reached the backend transition while the
four-second visual capture was still on the wait screen:

```text
[2026-08-09 17:17:24] SteamUI: WARNING: SetOOBEComplete
[2026-08-09 17:17:24] SteamUI: WARNING: OOBE Stage 2: completed
[2026-08-09 17:17:24] SteamUI: WARNING: No restart requested
[2026-08-09 17:17:24] SteamUI: INFO: Login: OnLoginStateChange  1 1 0 0
[2026-08-09 17:17:24] [ None ] SetLoginState: WaitingForCredentials - OK
```

This is stronger than a DOM-only claim because it is paired with the fresh
run's captured Steam frame, but it is not yet QR acceptance: neither physical
nor X11 pixels showed a QR code.

## Client and cleanup evidence

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
client_stdout=506
client_stderr=7095
```

```text
steam-client.log sha256=b5094d903eb3e11f12f4345e34d61277a2011c21b752365b3484e7eb47cda927
steam-client.stdout sha256=0d917fc0c257cbd766a095177db99024958915d8c89069f2bff4919cce14ac31
steam-client.stderr sha256=93a659fedb235fc26a981944d23796e11ae0756ee0a9519920f4a0c64d8ea350
android-input-sequence.txt sha256=4c4bcd0feb1dd442286a9e71895044c31a5ccc4bed183d41ca0ed7ca542e6d88
```

Cleanup was clean:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Decision and next step

The direct-X11 route has now crossed the OOBE/network boundary and entered
Steam's waiting-for-credentials state. The next isolated experiment keeps the
three-event sequence fixed and changes only the post-input settle from four to
twelve seconds, staying within the 60-second bound, to capture the resulting
login/QR surface after Steam has time to replace the wait frame.
