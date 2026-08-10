# Nova libei-enabled Gamescope touch/fullscreen retry result — 2026-08-10

Status: rejected before compositor launch; the preflight retry accumulator is
fixed, but both cleanup attempts still reported a transient matching runtime PID.

This is the result for the predeclared [run 229](229-nova-libei-gamescope-touch-fullscreen-retry-2026-08-10.md).

## Run identity and artifacts

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-libei-touch-fullscreen-retry-20260810T065557Z`.
- Run directory:
  `android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-retry-20260810T065557Z`.
- Harness repair under test: commit `2c877e7`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- APK SHA-256:
  `aea60e89574d5f2d396596dc00281d8b5f0b209059b5dd590d0e231d1ae6c0ce`.
- AHB metadata SHA-256:
  `2a1558e28cc787fe4b50ef92c06ec25c58db09b67b845d1232b23f3f4bd8ee4f`.
- Preflight manifest SHA-256:
  `0d4461bd29256473d64659998b3e47bdd6660adb9269075b9e2fc9eb871572ee`.

The artifact identity gates passed before preflight:

```text
gamescope_binary_sha256=cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
fullscreen_presentation=1
android_vulkan_layout_profile=1280x960 usage=0x333
```

The outer touch wrapper again reached the libei transport setup boundary:

```text
android_touch_socket_connected=pass
libei_connect=pass
libei_touch_seat=pass
libei_touch_device=pass
libei_touch_device_resumed=pass
```

As in run 227, these are setup markers only. No touch down/up event, Gamescope
frame, Steam surface, or AHB presentation was produced by this run.

## First failed layer

The repaired preflight evaluated attempts independently, and both attempts
failed the exact cleanup helper:

```text
preflight_cleanup=fail attempt=1 status=1
nova_runtime_cleanup=fail root=/data/local/tmp/nova-holo-rootfs attempts=3 term_pids=26902,27077,27101 kill_pids=27031,27142,27301 remaining=27306
preflight_residual_processes=pass attempt=1
preflight_cleanup=fail attempt=2 status=1
nova_runtime_cleanup=fail root=/data/local/tmp/nova-holo-rootfs attempts=3 term_pids=27497,27710,27832 kill_pids=27658,27779,27896 remaining=27949
preflight_residual_processes=pass attempt=2
preflight_app_files=pass attempt=2
preflight_ahb_trace_reset=pass attempt=2
preflight_socket_trace_reset=pass attempt=2
preflight_scheduler_trace_reset=pass attempt=2
preflight_manifest=fail run_id=gamescope-libei-touch-fullscreen-retry-20260810T065557Z
```

The exact residual-process audit immediately after each cleanup reported pass,
and the outer trap's final cleanup also reported pass. That disagreement is not
safe to reinterpret as a presentation result: the helper's own final check saw
a matching PID and fail-closed as required. The next repair must capture the
matching process arguments and lifecycle across the cleanup attempts so we can
distinguish a real respawn from a process-list race or an over-broad match.

## Decision

The retry accumulator repair is retained: it correctly preserved the cleanup
failure instead of turning it into a false preflight pass. The next change is a
narrow diagnostic enhancement to `nova-runtime-cleanup.sh`, followed by a fresh
cleanup-only/device run. Do not launch Gamescope until the exact cleanup helper
and the external residual audit agree on a clean state.

The metadata and preflight artifacts remain at the run directory above.
