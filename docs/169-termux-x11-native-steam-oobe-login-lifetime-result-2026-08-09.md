# Termux:X11 native ARM64 Steam OOBE login-lifetime result — 2026-08-09

Status: the 180-second lifetime extension did not produce a QR/login surface.
Steam remained in its credentials wait for the full client bound. The run also
caught a final-sample physical/X11 presentation discrepancy that must remain
visible in the evidence rather than being treated as a successful synchronized
frame.

## Run identity and provenance

```text
run_id=termux-x11-20260809T173100Z-native-steam-oobe-login-lifetime-display-0
repo_commit=d4ab29a498394070c35a4fb914b85c84f330e6c1
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=9d99f0b2fe09d46ac7842e30abc6921566c2e538b5a73529f4b30d0235630934
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
steam_timeout=180s
capture_delay_seconds=8
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
input_key_name=KEYCODE_ENTER
input_delay_seconds=1
input_after_delay_seconds=30
```

The mandatory [Nova runtime harness lifecycle](34-nova-runtime-harness-lifecycle.md)
was read immediately before launch. The fresh run passed exact-scope teardown.

## Input and capture gates

The same viewable X11 window survived all three focused Android key events:

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

Frame hashes:

```text
android_initial=c0f700aff27a78607055c489ff6a55721ecb864c5db7b7f302134b8ee0a0021f
android_step1_after=b4ae23621bc339e237f5a31a946cff9895f1678b13eb705d31a4c6e4b37a1ad3
android_step2_after=e7da2b5bebd531e76406cbb2c47bab167e028f29747e1d55619b4b32cb162b61
android_step3_after=c43748dfb46a879861c736df56cd884fb48b2ad9315e4556c7caa2d073399b64
x11_initial=554d20f84a44300a03f53d37afbd69f396d70faf0df355d7e19338d63f210086
x11_step1_after=2f8d4f1c1a6e83bedd35ce94f56836b72f3d91b92abf5c185aab3eef959f666f
x11_step2_after=833de2c28c0709763f81b2d27b0d3a65bdc6b98047ae0c49b7a11ab1b2019e35
x11_step3_after=33535ab880e52e720489e6985a758fb8a79ec58bcb96e6dabc423220d3ccdf6a
input_sequence=4c4bcd0feb1dd442286a9e71895044c31a5ccc4bed183d41ca0ed7ca542e6d88
```

The final X11 frame visibly contains the animated Steam logo and
`Waiting for network...`. The paired Android screenshot contains the Steam
logo but no visible wait text and includes the rooted-harness superuser toast.
This is a presentation mismatch at the final sample, not a QR pass; neither
capture contains a QR code or usable login controls.

## Lifetime and Steam state

The client remained alive until the new bound and then stopped cleanly:

```text
client_timeout_seconds=180
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
steam_client_log_sha256=8c305f989d8d14c1f63fdf85861e50c03e00fcad5f9aafc184f7d17d7769faef
steam_client_stdout_sha256=0d917fc0c257cbd766a095177db99024958915d8c89069f2bff4919cce14ac31
steam_client_stderr_sha256=3acdebe5a499900666bcea835239adc457f8a82d6f751540dd0b53197292b6b8
```

The fresh persistent logs reached the same state as the 60-second and
12-second runs, then emitted no later login transition during the remaining
client lifetime:

```text
[2026-08-09 17:31:10] Connectivity test (23.215.0.12:80): OK!
[2026-08-09 17:31:10] Connectivity test: result=Connected
[2026-08-09 17:31:11] CWebSocketConnection (steamUI): connection ready
[2026-08-09 17:31:11] CWebSocketConnection (clientdll): connection ready
[2026-08-09 17:31:11] WebUITransportStore: Connection status: connected
[2026-08-09 17:31:12] Login: OnLoginStateChange  1 1 0 0
[2026-08-09 17:31:12] [ None ] SetLoginState: WaitingForCredentials - OK
```

This rules out “the QR screen only needed a few more seconds” for this exact
client/profile. It does not yet identify whether the wait is caused by a
missing SteamClient user-startup state, an unavailable host service, or a
different login API contract.

## Cleanup

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
nova_runtime_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
```

## Decision

Do not extend the timeout again or change the compositor. The next experiment
should inspect the live Steam login page through its existing CDP endpoint and
record the presence, type, and return value of
`SteamClient.User.GetStartupUserChooserState()` alongside the route/body. The
login bundle renders `WaitingForNetwork` whenever its startup-user chooser state
is absent; a live API probe can distinguish that concrete contract boundary
from another speculative compatibility patch.
