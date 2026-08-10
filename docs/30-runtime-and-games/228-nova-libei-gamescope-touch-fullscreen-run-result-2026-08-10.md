# Nova libei-enabled Gamescope touch/fullscreen run result — 2026-08-10

Status: rejected before compositor launch; the run exposed a preflight retry bug,
not a libei or rendering result.

This is the result for the predeclared [run 227](227-nova-libei-gamescope-touch-fullscreen-run-2026-08-10.md).

## Run identity and artifacts

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-libei-touch-fullscreen-20260810T065012Z`.
- Run directory:
  `android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-20260810T065012Z`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Explicit Gamescope binary:
  `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`.
- Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- APK SHA-256 recorded by the run:
  `92280b5fee8665fe7b1697359b9fe6245b9839a629d85ac82b088477511a51e7`.
- AHB metadata SHA-256:
  `d7c9c8185d57aaf124dc7533a013e504bc4ab55b9817d568f05c10642a9b9a67`.
- Preflight manifest SHA-256:
  `7ee6815f3c450a71f1119612be9d5e26d81852d97ad6b8fa94ad1d5ef906d975`.

The run metadata passed the artifact identity gates:

```text
gamescope_binary_sha256=cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
fullscreen_presentation=1
android_vulkan_layout_profile=1280x960 usage=0x333
```

## What ran

The outer touch helper pushed the explicit libei-enabled binary and reached the
libei transport readiness boundary before invoking the nested AHB test:

```text
android_touch_socket_connected=pass
libei_connect=pass
libei_touch_seat=pass
libei_touch_device=pass
libei_touch_device_resumed=pass
```

These markers only prove socket/device setup. No touch down/up event was emitted,
and the nested AHB test did not launch Gamescope, Steam, or the Android AHB
presentation activity.

## First failed layer

The nested AHB test rejected its preflight:

```text
preflight_cleanup=fail attempt=1 status=1
preflight_residual_processes=pass attempt=1
preflight_cleanup=pass attempt=2
preflight_residual_processes=pass attempt=2
preflight_app_files=pass attempt=2
preflight_ahb_trace_reset=pass attempt=2
preflight_socket_trace_reset=pass attempt=2
preflight_scheduler_trace_reset=pass attempt=2
preflight_manifest=fail run_id=gamescope-libei-touch-fullscreen-20260810T065012Z
```

The first cleanup attempt saw a transient runtime PID. The second attempt
successfully cleaned it and every other preflight gate passed. However,
`deploy-gamescope-headless-ahb-test.sh` keeps one `gate_status` accumulator across
both attempts and never resets it after a successful retry. The script therefore
failed closed even though the final preflight state was clean. The outer cleanup
then passed, and an authoritative post-run device audit found no matching Nova
runtime process or rootfs mount.

## Decision

This run is not evidence for or against Gamescope touch, AHB presentation, Steam
visibility, or fullscreen geometry. It is evidence of a narrow harness defect:
retry success is not accepted. Repair the accumulator so that a retry is accepted
only when all gates in that final attempt pass, preserve the two-attempt cleanup
and residual-process checks, and rerun the same fixed-input touch/fullscreen
experiment under a new run ID.

The exact metadata and preflight artifacts remain at the run directory above.
