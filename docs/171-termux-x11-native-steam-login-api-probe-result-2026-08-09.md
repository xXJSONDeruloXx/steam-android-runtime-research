# Termux:X11 native ARM64 Steam login API probe result — 2026-08-09

Status: the live CDP probe passed and identified a concrete Steam UI bridge
boundary. The physical/X11 path remains active and captures the spinning Steam
login throbber, but the Gamepad UI login page cannot leave `WaitingForNetwork`
because its expected `SteamClient.User` methods are absent.

## Run identity and provenance

```text
run_id=termux-x11-20260809T174000Z-native-steam-login-api-probe-display-0
repo_commit=d06216c7da6b2ba455a7712a8e5b82c6c12cbfad
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

## Direct X11 and physical-screen gates

The direct presentation/input path remained healthy during the probe run:

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

```text
android_initial=cdde1ec961626bea9038debd3cc13b10f7900fdd046987816f28794d28a9f4ee
android_step1_after=113351f42d901b31f14d45da30c2ef7b1f9e9b0bbfbad11ce8102b4d47a98f6d
android_step2_after=9fd098db848852e1ad1e7febd69974924df89d5ecf6c8e7ae0f5cd170ca20f30
android_step3_after=75575e83e106d9fe8a964619f3bd98c5395ccbf410f0198e492c6e90707d7c68
x11_initial=fd9e47635f12e922920a750ea96d963d8bea92bacd2016016a16759dc9fda988
x11_step1_after=a9b842c0dab78ab08d717d032f8f4f308bc5765de9764a1965a7e8505de7ff44
x11_step2_after=593e2f484918204ad9439c00362c7bdedf9eef54474954c3b74f3feb279fc728
x11_step3_after=8a3dd08874cae7b66bddf37098e9c005aa4703bdcbba692fb7228ba4661607e4
input_sequence=4c4bcd0feb1dd442286a9e71895044c31a5ccc4bed183d41ca0ed7ca542e6d88
```

The Steam throbber continued to animate on the X11 capture; the Android
SurfaceView was live as well. No QR code or login controls were visible in the
paired captures. The earlier final-sample text discrepancy remains a reason to
keep Android/X11 frame identity explicit, but it does not invalidate the
active-display result.

## Read-only CDP evidence

The probe created an exact `tcp:9222 -> tcp:8080` ADB forward, queried the fresh
webhelper target, evaluated one read-only expression, and removed the forward.
The device-side forward list was empty after teardown.

```json
{
  "title": "Steam Big Picture Mode",
  "href": "https://steamloopback.host/index.html?...",
  "body": "5:40 PM\nWaiting for network...",
  "methods": {
    "getStartupUserChooserState": "undefined",
    "startLogin": "undefined",
    "getLoginUsers": "undefined",
    "getCurrentUser": "undefined"
  },
  "startupState": { "unavailable": true }
}
```

Artifact hashes:

```text
cdp_login_state=a21d4b96483d9014c8f491873ecab74d82913cba1428f4b989a8ab56fff52d94
cdp_targets=8baea82df450fd99ce6481a80e9f692287c834715860994d47f3bb5c9d9fe56e
adb_cdp_forward=f3391274ff6230706cde3bf74411dd636ad84979ef62113073934b359f86ffda
cdp_probe_status=4a1d6e892265f1cbaaa0652b11b5f8ec07d27af05c29c801e392b42ae091fcfc
```

The Steam logs from the same client session still recorded successful local
transport and basic connectivity:

```text
[2026-08-09 17:40:20] CWebSocketConnection (steamUI): connection ready
[2026-08-09 17:40:20] CWebSocketConnection (clientdll): connection ready
[2026-08-09 17:40:20] WebUITransportStore: Connection status: connected
[2026-08-09 17:40:21] Login: OnLoginStateChange  1 1 0 0
[2026-08-09 17:40:21] [ None ] SetLoginState: WaitingForCredentials - OK
[2026-08-09 17:40:16] Connectivity test (23.215.0.12:80): OK!
[2026-08-09 17:40:16] Connectivity test: result=Connected
```

## Why this is a networking-phase boundary

The shipped `steamui/chunk~2dcc5aaf7.js` login component contains a concrete
branch that calls `SteamClient.User.GetStartupUserChooserState()` and renders
the waiting state when that startup-user state is absent. The live page
confirmed that the whole `SteamClient.User` subset expected by this branch is
undefined. This is stronger evidence than a generic “Steam is waiting”: the
network route may be reachable while the native Steam-to-webhelper user/auth
bridge is not being registered in this Android-hosted session.

The next branch will therefore focus on connection and bridge provenance:
record Android versus chroot DNS/routes/sockets, identify which native Steam
client service supplies the missing `SteamClient.User` bridge, and test one
network/IPC boundary at a time. It will keep the proven Termux:X11 renderer,
CEF flags, input path, and cleanup contract fixed. No Gamescope-to-AHardwareBuffer
change is justified by this result.

## Cleanup

```text
cdp_probe_status=pass
namespace_cleanup=pass
nova_x11_cleanup=pass
nova_runtime_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
```
