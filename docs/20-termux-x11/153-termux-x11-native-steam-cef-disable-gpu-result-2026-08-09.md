# Termux:X11 native ARM64 Steam `-cef-disable-gpu` result — 2026-08-09

Status: positive partial result. The flag changed the physical Android
surface from solid white to a visible SteamOS splash logo on black. Steam
still did not reach a visibly captured OOBE/login/QR screen in the bounded
capture, and the X11 and Android captures were not the same frame.

## Run identity and provenance

```text
run_id=termux-x11-20260809T165000Z-native-steam-cef-disable-gpu-display-0
repo_commit=800727df6ceafd6345096c89a4b6e5ff5d10e1d7
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=405747d242d066ca544908f577c16cb73e600fcea185fbc469a10699a2a5b3a7
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
```

## Result

The final launcher evidence is complete and the flag is present in the
actual Steam command:

```text
client_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
client_stdout=506
client_stderr=5775
```

The Steam Big Picture window and nested webhelper surfaces were viewable, and
X11 capture passed for a 1280x800 window. The physical Android screenshot was
visually a black SteamOS splash screen with the white SteamOS logo and cursor;
it was materially different from the baseline's white surface. It contained
no OOBE controls, login form, or QR code.

```text
android-screenshot.png sha256=559b631ca81fc6fa6006db63fc4d1dca4265454b6575cb62f597f36cd84adabb
x11-window.ppm sha256=d4e96a65fd4f8e97bc1d762fc90cf2593bc2efb53a3125a72502fdae0f09395c
x11-tree.txt sha256=21182e202405bab83c355c39009b7a873099068d321062716890ca45217d17b3
x11-capture.txt sha256=af0b1544460202ebed338c4605904158b3844ab71a6aae6080664cc142ca6405
steam-client.log sha256=9cfec27c3f1d38ab505a420371e56131973c611642771b03652cc3bcc8273639
steam-client.stdout sha256=0d917fc0c257cbd766a095177db99024958915d8c89069f2bff4919cce14ac31
steam-client.stderr sha256=571c0a0f31769f6a6de32cf25be412d102dcda5ce5c73349812dca9bb5f88348
```

The X11 PPM was black at its capture instant while the immediately following
Android screenshot showed the splash logo. This is a timing/frame-identity
disagreement, not evidence that both surfaces displayed the same frame.

## Fresh CEF and Steam UI evidence

The fresh direct client stderr confirms the command-line flag was accepted.
The persistent Steam UI logs for this run then reached the same application
logic boundary as the baseline:

```text
[2026-08-09 16:46:53] Disabling GPU acceleration: Disabled/CommandLine
[2026-08-09 16:46:57] SteamUI: INFO: CWebSocketConnection (clientdll): connection ready
[2026-08-09 16:46:57] SteamUI: INFO: Login: OnLoginStateChange  0 1 0 0
[2026-08-09 16:46:58] SteamUI: INFO: OOBE Store: keyboards 1
```

The fresh GPU report changed materially from the baseline:

```text
GPU0 = ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (LLVM 10.0.0)))
Ozone platform = x11
gpu_compositing = disabled_software
opengl = disabled_off
vulkan = disabled_off
```

This proves the prior-art flag changes CEF's active mode and gets real Steam
pixels onto the Android surface, but the bounded screenshot was taken during
startup. The next run should keep this flag and delay the content capture long
enough to sample the post-`OOBE Store` state.

## Cleanup

All exact-scope cleanup markers passed without manual intervention:

```text
namespace_cleanup=pass
nova_x11_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Decision and next step

Keep `-cef-disable-gpu` as the leading path. Do not add another CEF flag yet.
First add a run-scoped delayed screenshot/X11 capture after the webhelper has
had time to pass its startup splash, and record the paired capture timing. The
milestone remains the actual physical Steam OOBE/login/QR view.
