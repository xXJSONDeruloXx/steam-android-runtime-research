# Nova FROG WSI Gamescope socket-mode probe — 2026-08-10

## Question

The prior run established that FROG can see `/tmp/gamescope-0`, but the
Gamescope-created socket is root-owned with mode `0755` while the child runs
as Steam uid 501. This fresh permission-isolation experiment stages the
tracked `nova-frog-socket-mode-probe.sh` as the Gamescope child. The root
wrapper waits for the compositor socket, records its mode, changes only the
Gamescope and libei socket modes to `0777`, records the result, then drops to
uid 501 and runs the same FROG/Vulkan probe.

The experiment asks whether socket write permission is the immediate FROG
failure. It is intentionally a diagnostic workaround; it does not yet change
Gamescope or the one-click launcher product path.

## Run identity and fixed artifacts

- Run ID: nova-frog-wsi-gamescope-socket-mode-20260810T092142Z
- Device: Retroid Pocket Nova, serial 675a2365
- Rootfs: /data/local/tmp/nova-holo-rootfs
- Gamescope: /opt/nova-kgsl-driver/gamescope-headless
- Gamescope SHA-256:
  cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
- Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
- APK SHA-256:
  3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a
- FROG layer: VK_LAYER_FROG_gamescope_wsi_aarch64
- ICD: /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
- Headless output/nested size: 64x64
- Runtime directory: XDG_RUNTIME_DIR=/tmp
- Executable search path: PATH=/usr/bin:/bin
- Probe script: android/nova-lab/device/nova-frog-socket-mode-probe.sh

The probe script is staged only in the run's disposable rootfs `/tmp` and is
removed during teardown. Its SHA-256 is recorded with the run artifacts.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the APK
and Termux:X11, run exact preflight cleanup, establish fresh process,
mount/socket, and launcher-state baselines, install the probe script, and
launch only this run. Capture the complete Gamescope/child stdout and stderr,
socket modes before and after, FROG messages, Vulkan output, launcher logs,
and same-run screenshots.

If FROG connects after the mode change, record its application/surface result
separately from the permission workaround. A successful `vulkaninfo --summary`
without a FROG connection is not a pass.

After capture, remove the staged probe, force-stop the APK and Termux:X11, run
both exact cleanup helpers, and verify no matching Gamescope,
gamescopereaper, Xwayland, Steam/Wine/Proton, libei, or uinput process remains.
Retain only the two baseline rootfs udev sockets. This declaration is
committed and pushed before the device run.
