# Termux:X11 native ARM64 Steam delayed CEF capture result — 2026-08-09

Status: major positive result. With `-cef-disable-gpu` retained and an eight
second post-window delay, native ARM64 Steam rendered its actual OOBE welcome
and language-selection screen through Termux:X11 onto the physical Retroid
Pocket Nova display. The paired X11 capture showed the same OOBE scene.

## Run identity and provenance

```text
run_id=termux-x11-20260809T170000Z-native-steam-cef-delay8-display-0
repo_commit=f86d8ec25b4d04bbc9e39a16d3bbe555df1e5eb7
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=405747d242d066ca544908f577c16cb73e600fcea185fbc469a10699a2a5b3a7
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
x11_window_wait_seconds=25
x11_capture_delay_seconds=8
```

The run was launched only after reading the mandatory [Nova runtime harness
lifecycle](34-nova-runtime-harness-lifecycle.md). It used a fresh run ID and
the exact-scope cleanup helper before and after the session.

## Client and capture result

The final host-side launcher evidence was complete:

```text
termux_x11_server=pass display=:0 socket=...
termux_x11_window=pass id=0x2400035
termux_x11_capture_delay=pass seconds=8
termux_x11_android_capture=pass sha256=1d8ae36b3bdbe0a26ed3a7d8d5327e764776000c1517a1f753fcd370234c270e
termux_x11_x11_capture=pass sha256=17e89aa8864e7eb1b0ff84811f5116a7dbb94e4bee18f5e7b07d496ff04bd0fa
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
client_stdout=506
client_stderr=5775
termux_x11_post_stop=pass
```

Steam stayed alive for the complete 60-second bound. The timeout is therefore
an expected harness stop, not a startup crash or an incomplete log snapshot.
The viewable X11 tree contained the Steam Big Picture window and nested
webhelper surfaces:

```text
nova_x11_window id=0x2400035 parent=0x511 depth=1 map_state=viewable x=0 y=0 width=1280 height=800 name="Steam Big Picture Mode" res_name="steamwebhelper" res_class="steam"
nested 0xe00006 / 0xe00008 viewable
```

The exact Steam command retained the prior-art renderer workaround:

```text
client_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu
```

## What was visibly rendered

Both captures showed the same actual Steam OOBE scene rather than a splash or
blank surface:

- dark Steam background with a large `Welcome` heading;
- `Select a language` prompt;
- the language dropdown expanded on the right, with `English` selected at the
  top and additional languages below;
- Steam's bottom navigation strip with `STEAM MENU` and `A SELECT`.

The physical Android screenshot also shows the Android status bar,
Termux:X11 extra-key bar, and cursor around the Steam content. This is the
first Termux:X11 run in this branch with a real Steam OOBE control visible on
the device. It is not yet the QR/login screen.

```text
android-screenshot.png sha256=1d8ae36b3bdbe0a26ed3a7d8d5327e764776000c1517a1f753fcd370234c270e
x11-window.ppm sha256=17e89aa8864e7eb1b0ff84811f5116a7dbb94e4bee18f5e7b07d496ff04bd0fa
x11-tree.txt sha256=a95fda99d4ee79212a80859d4b320dcd8b2f46028ed3429dac3fa289bfa69a48
x11-capture.txt sha256=f60ee6c5ae52b7e5e393c15f831f49b9043f74f60ef1464be2bdaa1794f67740
termux-client.log sha256=ad609d151c1cca2a814d64533fb0d3430a7922bbaefb82684bbd181e5db40c98
termux-client.stdout sha256=84e040acd6f69a522ec3749384fdfc22b3468539bb7d024a1046398cf82d8f2a
termux-client.stderr sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
steam-client.log sha256=b87c5734ac5cb6ba396a30aed724b6ea75d617d4af08fe37963d2b78654a62d1
steam-client.stdout sha256=0d917fc0c257cbd766a095177db99024958915d8c89069f2bff4919cce14ac31
steam-client.stderr sha256=32aae94971bf2482a1f6bcca6e7ecda7d6b2ea9e8c6d96e839b2f526d33bf04b
cleanup sha256=a279d806a6d514c054119c807aa6c7bd7195a889eb78a5e8ca7edd069f25e0f8
post-stop sha256=eb46f9cc98bb5005af5212d52f6cb55cc48be550659a9fa90ed6181ee3f6cbca
runtime sha256=1bb8add9bfa2a0ad115fa08807f1927364b44300ae706823e12964cc74539be8
```

## Fresh Steam and CEF evidence

The persistent Steam UI log for this run reached the connected pre-login
boundary and initialized the OOBE store:

```text
[2026-08-09 16:51:02] Client version: no bootstrapper found
[2026-08-09 16:51:03] CWebSocketConnection ... connection ready
[2026-08-09 16:51:03] WebUITransportStore: Connection status: connected
[2026-08-09 16:51:03] Login: OnLoginStateChange 0 1 0 0
[2026-08-09 16:51:04] OOBE Store: keyboards 1
```

The fresh CEF report still identifies software rendering, but now with GPU
acceleration explicitly disabled:

```text
GPU0 = ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (LLVM 10.0.0)))
Ozone platform = x11
gpu_compositing = disabled_software
opengl = disabled_off
vulkan = disabled_off
```

This makes the causal interpretation stronger than the splash-only run: the
`-cef-disable-gpu` mode is sufficient to carry live Steam web UI pixels from
CEF through X11 and Termux:X11 to Android, and the eight-second delay samples
the same post-startup frame on both capture paths.

## Cleanup

All exact-scope cleanup markers passed:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Decision and next step

This closes the display-side blocker for the Termux:X11 line. Do not return to
the Gamescope/AHardwareBuffer compositor seam yet. The next experiment should
preserve this exact launch profile and add a controlled input action for the
already-open language selector, with a fresh post-input X11/Android capture.
Before launching it, document and push the input method and its acceptance
gate. Continue one interaction at a time until Steam reaches the QR login
view, recording any network, focus, input, or OOBE-specific blocker as its own
experiment.
