# Nova raw AHardwareBuffer snapshot experiment — 2026-08-09

Status: completed; see [the raw AHardwareBuffer snapshot result](112-nova-ahb-raw-snapshot-result-2026-08-09.md).

## Question

The optimal-tiling run in [doc 110](110-nova-optimal-tiling-steam-surface-result-2026-08-09.md)
proves changing logical AHB checksums and a native Steam scene on settled X11,
but the Android screenshot still shows green diagnostic lines. This experiment
captures one bounded, logical RGBA8 AHardwareBuffer frame before the test-bench
marker is written. It separates the Gamescope external-image write boundary
from the Android SurfaceControl/HWC consumer boundary.

## Instrumentation under test

When explicitly enabled, the APK reads the selected AHB after its acquire fence
and writes exactly `width * height * 4` bytes as tightly packed logical RGBA8
rows to its private app-files directory:

```text
debug.nova.ahb_raw_capture=1
debug.nova.ahb_raw_capture_frame=239
files/nova-ahb-raw-frame.rgba
```

The snapshot is taken before the optional frame marker is written. The app
report records the selected producer frame, AHB descriptor, stride, usage,
byte count, path, and pre-marker checksum. The host harness verifies the exact
byte count, correlates the raw-capture report line, and decodes the snapshot
with `decode-nova-ahb-raw-frame.py` into a PNG. The default remains disabled;
cleanup and post-stop verification remove the file and reset both properties.

## Run contract

```text
run_id=controller-ui-20260809T130645Z-raw-ahb-1280x960
profile=controller-ui-raw-ahb-1280x960
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope=/tmp/nova-gamescope-ahb-tiling-libei-20260809-out/src/gamescope
gamescope_sha256=29c62f0b19aee09e111909cf6bee0c3df8b306380d93e133a1affa22b83bcfc0
gamescope_source_tree=/tmp/nova-gamescope-ahb-tiling-libei-20260809-source
fullscreen_presentation=1
fullscreen=1280x960
ahb_buffer=1280x960
ahb_usage=0x333
ahb_frames=240
NOVA_AHB_OUTPUT_TILING=optimal
NOVA_AHB_FRAME_IDENTITY=1
NOVA_AHB_FRAME_MARKER=1
NOVA_AHB_CONTENT_PROBE=1
NOVA_AHB_RAW_CAPTURE=1
NOVA_AHB_RAW_CAPTURE_FRAME=239
NOVA_AHB_TRACE=1
NOVA_AHB_SOCKET_TRACE=1
NOVA_AHB_SCHEDULER_TRACE=1
NOVA_AHB_ACK_POLL_TIMEOUT_MS=0
NOVA_STEAM_CLIENT_TIMEOUT=180
NOVA_STEAM_GAMESCOPE_TIMEOUT=300
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=240
NOVA_CONTROLLER_UI_SETTLE_DELAY=30
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent
NOVA_CONTROLLER_UI_ANDROID_KEYCODE=96
NOVA_CONTROLLER_UI_EVENT_CODE=304
NOVA_CONTROLLER_UI_X11_CAPTURE=1
NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1
NOVA_CONTROLLER_UI_OVERLAY_GUARD=1
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1
```

The Gamescope binary and source identity remain fixed to the prior valid
optimal-tiling run. The APK currently built at predeclaration has SHA-256
`258ff7d42adc48c5dc1d43b22368714d3ad1f0d8fdaf6e519539382fb37f3c7e`.
`build.sh` is invoked by the deploy harness and currently emits timestamped
ZIP/signature entries, so the exact post-build APK hash in the fresh run
metadata is authoritative for this experiment; this packaging nondeterminism
is recorded as a follow-up reproducibility issue rather than hidden.

The software CEF/GL profile (`swrast`, `softpipe`) remains fixed. No Android
input event is accepted unless the strict Android Steam-surface gate passes.

## Acceptance gate

The raw-capture implementation is accepted only if the same fresh run records:

```text
ahb_double_buffer_raw_capture=enabled target_frame=239
ahb_double_buffer_raw_capture_239=pass
ahb_raw_capture=pass frame=239 bytes=4915200
nova_ahb_raw_decode=pass
ahb_double_buffer_frames=240 releases=239
post_stop_raw_capture_state=pass
post_stop_verification=pass
```

The retained `.rgba` file must be exactly 4,915,200 bytes, and the decoded
PNG must be 1280×960 RGBA. Existing optimal import, frame identity, content
probe, marker, native Steam smoke, and settled X11 capture checks remain in
force. This run does not claim gamepad navigation if the Android surface is
missing.

## Decision branches

- If the raw PNG contains Steam pixels while the Android screenshot remains
  green lines, focus on SurfaceControl/HWC import, cache visibility, or the
  physical layout/consumer path.
- If the raw PNG itself contains green lines, focus on Gamescope's Vulkan
  external-image write, format, stride, and image-transition path.
- If the raw file, descriptor correlation, or cleanup gate fails, reject the
  result as invalid and retain the exact failure; do not escalate to input or
  login.

## Reproducibility and cleanup

Read [the full lifecycle contract](../00-start-here/34-nova-runtime-harness-lifecycle.md)
before launch. Use a fresh run directory and run identity. The harness must
clear the app-owned raw file before launch and on every exit, reset
`debug.nova.ahb_raw_capture` and `debug.nova.ahb_raw_capture_frame`, and run
the explicit post-stop verifier. The raw file, decoded PNG, decoder report,
app report, metadata, screenshot, X11 capture, and verifier are retained under
the run directory after teardown.
