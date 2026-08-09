# Nova AHB valid-content timeout-split result — 2026-08-09

Status: AHardwareBuffer transport and native Steam startup passed; the
controller/UI acceptance gate remained partial because the outer controller
harness timed out before it could sample a ready Steam surface.

## Artifact and run identity

This was the predeclared doc 91 experiment. It changed only the nested client
timeout relative to doc 90:

```text
run_id=controller-ui-20260809T-oobe-a-button-valid-content-cadence-timeout-split
profile=controller-ui-oobe-a-button-valid-content-cadence-timeout-split
run_started_utc=2026-08-09T09:40:30Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
binary_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
apk_sha256=c493463f0cc59346919afcf870e55cbc0a0a61690e97f01ad737bdc2892d8a31
fullscreen_presentation=1
nova_ahb_trace=1
nova_ahb_socket_trace=1
nova_ahb_scheduler_trace=1
nova_ahb_frame_identity=1
nova_ahb_frame_marker=1
nova_ahb_ack_poll_timeout_ms=0
steam_client_timeout=180
steam_gamescope_timeout=300
```

The binary is the libei-enabled build of the valid-content cadence change
from commit `15f95a2`. Its source and patch-stack identity are recorded in
the run's `device-gamescope-headless-ahb-metadata.txt` and preflight
manifest.

## Results

The compositor/output contract passed again:

```text
ahb_frame_marker_capture=pass frame=239 checksum_low16=0383
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer=pass
headless_gamescope_ahb=pass
headless_ahb_residual_processes=pass
nova_app_runtime_files_cleanup=pass
```

The app report contains 240 consecutive frames. Each frame passed Linux
import, GPU write, image write, acquire-fence, SurfaceControl completion, and
ACK checks. The frame-identity checksum stayed at
`e9d70e8ba2210383` with marker low 16 bits `0383`; the device capture has
SHA-256
`3be15e15d8df510aba753ce579138a0e0a75b1c7c5f6a552e08ff8545ef15305`.
That capture is still the dark marker-only surface, not visible Steam UI.

The timeout split fixed the earlier bookkeeping race. The fresh client log
now reaches every native startup marker:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
native_steam_smoke=pass
```

The input probe also found Steam holding the virtual controller device:

```text
steam_input_fd=pass
steam_input_fd_probe=pass
```

No A-button was sent. The controller relay recorded
`uinput_event_forwarded=none` and `android_key_forwarded=none`, while the
Android app report only reached device discovery and socket connection. The
outer harness printed `controller_ui_surface=missing` and did not produce a
navigation result.

## Timing interpretation

The nested Steam client wrapper now has enough time to finish its 180-second
wait and write `client_status`/`client_installed`, but the outer
`deploy-native-steam-controller-ui-input-smoke-test.sh` still defaults to a
140-second `NOVA_CONTROLLER_UI_WAIT_TIMEOUT`. It therefore stops waiting for
the fresh `steamwebhelper`/Steam UI readiness markers before the nested client
has finished its allowed startup window. This run proves the client-marker
race is fixed, but it does not yet distinguish a late UI from a permanently
missing UI surface.

The client output contains additional diagnostics that must remain
hypotheses, not conclusions: Steam selected `Using update UI: glx`, reported
missing Vulkan `VK_KHR_surface` and `VK_KHR_xlib_surface` extensions, reported
that `XRRGetOutputInfo()` was unavailable, and logged missing session/system
DBus connections. The same stderr also contains repeated SysV semaphore
shim `EAGAIN` results. None of these messages alone proves which condition
prevents visible Steam UI, because the controller readiness window expired
first.

## Decision and next experiment

Keep the valid-content cadence change. Keep the nested timeout split. Repeat
the same run with one additional harness-only change:

```text
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=240
NOVA_STEAM_CLIENT_TIMEOUT=180
NOVA_STEAM_GAMESCOPE_TIMEOUT=300
```

The next run must either reach the existing Steam surface and navigation
checks or capture a fresh, same-run failure after the full client startup
window. Only after that result should we change software GL/CEF, session-bus,
network, audio, or presentation code.

The complete artifacts are under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-oobe-a-button-valid-content-cadence-timeout-split/
```

