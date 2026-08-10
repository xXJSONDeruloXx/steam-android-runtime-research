# Nova native Steam Gamepad UI through Android AHardwareBuffer

Test date: 2026-08-08
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This is the first end-to-end Android presentation result for the native ARM64
Steam client in this repository. A real Valve ARM64 Steam process launches as
uid 501 inside the disposable Holo glibc rootfs, starts `steamwebhelper`,
reaches SteamUI WebSocket readiness, and produces a visible Gamepad UI welcome
screen through Xwayland, patched headless Gamescope, Android
`AHardwareBuffer`, and an `ASurfaceControl` child of the app's `SurfaceView`.

It is still a pre-login smoke test. It does not prove account login, controller
input, a launched game, suspend/resume, or hardware-accelerated CEF rendering.

## Reproducible test

The UI wrapper runs the existing native Steam smoke test in the background,
waits for a live `steamwebhelper` process, the newly appended SteamUI
`connection ready` and OOBE initialization markers, plus the current app's
first in-flight AHardwareBuffer frame marker, then captures the Android screen
while the Linux session is still alive,
then waits for the normal Gamescope/AHardwareBuffer frame and fence checks to
finish:

```sh
android/nova-lab/deploy-native-steam-ui-smoke-test.sh
```

The default bounded run uses 120 output frames at 960x540, a 180-second Steam
budget, and a 220-second Gamescope budget. The screenshot and raw diagnostic
logs are generated under the ignored `android/nova-lab/build/` directory:

```text
native-steam-live-screenshot.png
native-steam-ui-smoke.log
nova-steamui_html-latest.txt
nova-webhelper_js-latest.txt
nova-webhelper_gpu-latest.txt
nova-console_log-latest.txt
```

Use `NOVA_STEAM_UI_CAPTURE_DELAY` to adjust the post-OOBE settle window before
capture, or set `NOVA_AHB_FRAME_COUNT` higher when a longer live window is
useful for manual inspection. The default settle window is 20 seconds because
the Gamepad UI can still be transitioning away from its splash frame immediately
after the OOBE log marker.

The accepted run returned:

```text
headless_gamescope_ahb=pass
native_steam_smoke=pass
live_screenshot=android/nova-lab/build/native-steam-live-screenshot.png
native_steam_ui_smoke=pass
```

The underlying native client log recorded the expected bounded timeout rather
than an early exit:

```text
client_uid=501
client_gid=20
client_runtime_dir=/tmp/nova-steam-runtime
client_runtime_owner_status=pass
client_runtime_files_bin=.../steamrt3c_platform_3c.0.20260714.251839/files/bin
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
```

The compositor report recorded 120 Turnip-composited AHardwareBuffer frames,
120 target frames, successful output-probe completion, and no acquire-fence
handoff failure:

```text
android_ahb_composite_frame=120 layers=1 async=0
android_ahb_target_reached=120
offscreen_probe_status=0
probe_status=0
```

The Android log reports the matching two-buffer contract with 120 completed
SurfaceControl frames and 119 returned release fences.

## SteamUI evidence

The current Steam logs contain the full startup transition:

```text
Started webhelper process <pid>
BrowserReady: handle:65536
CWebSocketConnection (steamUI): websocket open
CWebSocketConnection (clientdll): websocket open
CWebSocketConnection (steamUI): connection ready
CWebSocketConnection (clientdll): connection ready
SteamApp Init - Before Login - Client transport
Login: OnLoginStateChange  0 1 0 0
OOBE Store: keyboards 1
```

The live screen capture shows the Steam Gamepad UI welcome screen and language
selector inside the 960x540 Android presentation area. This is stronger than
the earlier `BrowserReady`-only result: the Steam UI is now visibly crossing
the complete X11/Wayland/Android output path while the processes are alive.

## Changes that closed the previous boundary

The current launcher and seed preparation make four disposable-rootfs details
explicit:

- `XDG_RUNTIME_DIR` is created as `0700` and chowned to the selected Steam uid/gid.
- `/etc/machine-id` is generated once and `/var/lib/dbus/machine-id` points to it.
- `steamrtarm32` aliases the available native `steamrtarm64` diagnostic tools.
- SteamRT3C's ARM64 `files/bin` directory is added to `PATH`, making its
  dynamically linked `lsof` available to Steam's IPC diagnostics.

The last item changed the evidence from repeated `lsof ... command failed: 127`
messages to concrete localhost peer records. After that change both SteamUI
WebSocket connections reached the open/ready state without adding a fake
transport or bypassing Steam's authentication message.

The Android lab app also has a presentation-only launch mode. It disables the
lab's animated parent `SurfaceView` probe while retaining the top-layer
SurfaceView needed by the child `ASurfaceControl`; otherwise the lab animation
could mask the live Steam buffer or the post-run screenshot could show only the
activity after Gamescope had already been torn down.

## Rendering boundary

Gamescope's Android output is composited with the Nova Turnip driver, but the
Steam CEF report for this run identifies the browser renderer as software:

```text
GPU0: ANGLE (Mesa, softpipe, OpenGL 3.3 ... Mesa 25.2.7-arch1.1)
XDG_SESSION_TYPE: x11
gpu_compositing: enabled
vulkan: disabled_off
```

Therefore the current result proves visual SteamUI presentation and the
Android fence/SurfaceControl contract, not hardware-accelerated
`steamwebhelper`. The earlier Nova CPU/SVE fault and the current conservative
`swrast`/`softpipe` profile remain the next graphics-performance investigation.

## Remaining gates

- Complete Steam login and retain the authenticated Gamepad UI.
- Forward Nova controller input and prove navigation without adb input hacks.
- Replace software CEF rendering with a stable Adreno/Turnip or other hardware
  path, then measure frame pacing and memory use.
- Launch one ARM64-native or FEX/Proton game through the same session.
- Add clean stop, restart, and suspend/resume checks for the Android supervisor.
- Separate the root-required lab proof from a later rootless process/presentation
  boundary.

The preceding seed, package, ABI, and bootstrap investigations remain in
[docs/14](14-nova-steam-arm64-seed-and-startup.md); this document records the
follow-up result that supersedes its earlier “webhelper not observed” boundary.
