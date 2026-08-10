# Nova AHB valid-content cadence result — 2026-08-09

Status: compositor/output boundary passed; end-to-end Steam UI acceptance
rejected because the bounded Steam client did not reach the installed/UI
marker before the controller harness stopped.

## Artifact and run identity

The implementation is commit `15f95a2` (`fix: cadence Nova AHB after valid
content`). The ARM64 Gamescope binary was rebuilt with libei enabled by
incrementally recompiling `steamcompmgr.cpp` and relinking the existing
Gamescope build:

```text
binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
binary_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
libei=enabled
source=/tmp/nova-gamescope-frame-identity-final.AOqe48/source
source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
source_diff_sha256=ed675c36d4e8a01f85246a719a7a1edb68e337a5ffa953d028be5f87eaf99220
source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
```

The build configured `input_emulation=enabled`, found `libeis-1.0`, compiled
the cadence code, and linked successfully. The optional `v4l-utils`
subproject remained disabled because the build image did not contain
`doxygen`; it is not used by the headless AHardwareBuffer path.

The fresh device run used:

```text
run_id=controller-ui-20260809T-oobe-a-button-valid-content-cadence
profile=controller-ui-oobe-a-button-valid-content-cadence
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
apk_sha256=2fea6869cfc99b106b5bb333ca202dcdaa6e9f1b1a186d9b73db58da1b68c8dc
run_dir=android/nova-lab/build/manual-runs/controller-ui-20260809T-oobe-a-button-valid-content-cadence
```

The run kept fullscreen 1280x960, software CEF/GL, AHB frame identity and
marker capture, scheduler/socket traces, `NOVA_AHB_ACK_POLL_TIMEOUT_MS=0`,
the Android `KEYCODE_BUTTON_A` -> `BTN_SOUTH` mapping, and the overlay guard.

## Result

The valid-content cadence hypothesis worked at the Gamescope/AHB boundary:

```text
ahb_frame_marker_capture=pass frame=239 checksum_low16=0383
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer=pass
headless_gamescope_ahb=pass
headless_ahb_residual_processes=pass
nova_app_runtime_files_cleanup=pass
```

The app report contains 240 consecutive producer frames. Every frame had a
successful Linux import/GPU write/image write/acquire-fence/SurfaceControl
completion/ACK path, and the final frame had
`nova_output_frame=239`, `checksum_low16=0383`, and a completed present fence.
The marker capture is `device-gamescope-headless-ahb-screenshot.png` in the
run directory; its SHA-256 is
`3be15e15d8df510aba753ce579138a0e0a75b1c7c5f6a552e08ff8545ef15305`.

The scheduler trace shows the intended transition. Before valid content,
vblank continued with `has_repaint=0` and `should_paint=0`. Once
`paint_all()` observed valid contents, the trace changed at monotonic
`101095180144714` to `has_repaint=1` and `should_paint=1`; subsequent vblanks
continued to produce `present_call`/`present_return` pairs. The prior quiet-
scene gap therefore did not recur under this producer path.

The full acceptance gate was still rejected. The screenshot is dark gray with
the AHB frame marker but no visible Steam UI. The native Steam log recorded
`client_started=pass`, but stopped before `client_status` and
`client_installed`; the harness consequently reported:

```text
missing native Steam smoke marker: client_installed=pass
controller_ui_run_status=1
native_steam_controller_ui_input_smoke=fail underlying_status=1
```

This is a separate startup/harness failure, not evidence against the cadence
patch. `NOVA_STEAM_CLIENT_TIMEOUT` and `NOVA_STEAM_GAMESCOPE_TIMEOUT` were
both 300 seconds. The nested client wrapper writes its post-wait markers only
after waiting for Steam, while the outer Gamescope timeout kills the wrapper
at the same deadline. The next run must separate those deadlines before
judging Steam UI, login, or input.

## Decision and next experiment

Keep the valid-content cadence patch as the current compositor hypothesis: it
removed the scheduler-side quiet-scene stall without reproducing the earlier
global-trigger dark capture. Do not call this Steam login acceptance.

First repeat the same run with one harness-only change,
`NOVA_STEAM_CLIENT_TIMEOUT=180` while retaining
`NOVA_STEAM_GAMESCOPE_TIMEOUT=300`, and require the client log to reach
`client_status`, `client_installed`, and the UI/navigation markers. If that
run reaches a visible Steam surface, repeat once with
`NOVA_AHB_SCHEDULER_TRACE=0` as predeclared in doc 89. Only then move on to
networking/login, audio, hardware CEF/GL, touchscreen, and standalone-app
acceptance.
