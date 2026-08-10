# Nova libei-enabled Gamescope touch/fullscreen matcher-fix result — 2026-08-10

Status: cleanup matcher passed and the full AHardwareBuffer compositor path ran;
Steam UI readiness failed at the native Steam Vulkan/X11 initialization boundary.

This is the result for the predeclared [run 233](233-nova-libei-gamescope-touch-fullscreen-matcher-fix-2026-08-10.md).

## Run identity and artifacts

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-libei-touch-fullscreen-matcher-fix-20260810T070303Z`.
- Run directory:
  `android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-matcher-fix-20260810T070303Z`.
- Matcher fix commit: `e3065c1`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Gamescope binary SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- APK SHA-256:
  `7cbcd2e18d35e0af1f77e66e9b2595ba9c0d1c9e0a15798935bc2ebf04202d4d`.
- Metadata SHA-256:
  `be220746d4a9c85c7157ed2157c6968b2898a658931f34ac1468d905f97393f3`.
- Preflight SHA-256:
  `96f88b127c5d7b28ab5c00ea0f1ab905f8e093acf32c4ea9369c36a8a79b7576`.
- AHB report SHA-256:
  `0b4fa3a906bed42c53c933d3856c2e277aa8638c60e26d7b189320301c125780`.
- Screenshot SHA-256:
  `58993a39c54f390bbb8466c3105e964a8f07b57ea9d9e25d199b303807100b13`.

## What passed

The fixed cleanup gate passed without classifying the outer touch helper's
Magisk policy-log calls as Nova runtime. The fresh report records:

```text
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
vulkaninfo_status=0
Android AHardwareBuffer output imported: 3 x 1280x960 RGBA
Successfully initialized libei for input emulation!
android_ahb_composite_frame=120
android_ahb_target_reached=120
headless_gamescope_ahb=pass
```

The Android app also reports 120 successful AHB buffer presents with import,
GPU write, image write, acquire fence, SurfaceControl latch, and release-fence
markers. The current screenshot is a fresh `1280x960` AHB artifact, though it is
mostly dark/blank because Steam did not produce a ready UI frame.

Touch setup reached the socket, libei seat, device, and resume boundaries:

```text
android_touch_socket=listening
android_touch_socket=connected
android_touch_socket_connected=pass
libei_connect=pass
libei_touch_seat=pass
libei_touch_device=pass
libei_touch_device_resumed=pass
```

No `libei_touch_down_sent`, `libei_touch_up_sent`, or Gamescope EIS touch-event
marker exists because the smoke test intentionally stopped when Steam readiness
failed.

## First failed layer

The native Steam client metadata confirms the intended software-GL isolation was
active:

```text
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_libgl_always_software=1
client_started=pass
client_installed=pass
client_status=124
client_timeout=expected
```

Its fresh stdout nevertheless reports:

```text
Vulkan missing requested extension 'VK_KHR_surface'.
Vulkan missing requested extension 'VK_KHR_xlib_surface'.
BInit - Unable to initialize Vulkan!
```

The Steam client did not reach the SteamUI/webhelper readiness markers before
the bounded client timeout. Gamescope also logged `Unhandled libei event!`, but
there is no touch down/up evidence, so that message cannot yet be attributed to
a user gesture or called a touch-navigation failure.

## Decision

This closes the cleanup and AHB presentation gates but does not close Steam UI,
touch navigation, gamepad, audio, or product-APK acceptance. The low-level
Gamescope → AHB path is now proven independently; the next useful work is the
direct Termux:X11 path that already reached authenticated Steam UI, including a
small-library game trial such as Geometry Wars. Keep the Gamescope/AHB result as
a separate evidence-backed path and revisit its Steam Vulkan/X11 surface setup
after the direct path has produced game-launch evidence.
