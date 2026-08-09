# Nova Linux bridge lab

Operational guide for the rooted Retroid Pocket Nova experiments. The lab is
an evidence-producing sequence of Android, Linux-userspace, Gamescope,
presentation, Steam, and input probes; it is not a distributable Steam client
or Linux image.

Current device facts: Retroid Pocket Nova, Snapdragon `kalama`/Adreno 740,
rooted Android 13/API 33 lab image. Generated APKs, rootfs files, binaries,
captures, and run logs belong under the ignored `build/` tree.

## Scope and current boundary

The lab validates these layers independently:

1. Android `Surface`/`AHardwareBuffer` allocation and native-handle transfer.
2. Rooted private-mount/chroot access to the Android GPU, input, and system
   namespaces.
3. Holo ARM64 glibc userspace with Mesa/Turnip and Vulkan DMA-BUF handoff.
4. Patched headless Gamescope composition and Android
   AHardwareBuffer/SurfaceControl output.
5. Native ARM64 Steam startup, SteamUI readiness, controller/touch input, and
   source-vs-Android capture.

The Nova reaches the pre-login Steam Gamepad UI through the Android output
path. Hardware CEF, account login, game launch, audio, and clean long-lived
lifecycle behavior remain open. The current frame-level ACK/release issue is
summarized in [`docs/nova-ahb-transport-investigation-summary.md`](../../docs/nova-ahb-transport-investigation-summary.md).

## Prerequisites

- Android SDK/NDK command-line tools and a connected rooted Nova.
- `adb` access; set `ADB=/path/to/adb` when the host does not have the default
  local path used by the scripts.
- A disposable Holo/Arch-compatible rootfs and the package/network access used
  by the fetch/install scripts.
- An ARM64 Gamescope source tree and an explicit build directory for headless
  Gamescope experiments.
- Read [`docs/34-nova-runtime-harness-lifecycle.md`](../../docs/34-nova-runtime-harness-lifecycle.md)
  before any Nova device run. Its cleanup and provenance rules are mandatory.

## Android and buffer smoke tests

Build and run the base Android probes:

```sh
android/nova-lab/build.sh
android/nova-lab/deploy-and-test.sh
```

The app's root probe checks the private mount namespace and device-node access.
The native-buffer and Android-Vulkan probes check handle transfer and GPU image
import. The cross-process Linux bridge extends that handoff through a
SurfaceControl child of the app surface:

```sh
android/nova-lab/deploy-ahb-bridge-test.sh
VULKAN_AHB_ASYNC_FENCE=1 android/nova-lab/deploy-ahb-bridge-test.sh
android/nova-lab/deploy-ahb-double-buffer-test.sh
```

The `double-buffer` script name is retained for historical compatibility; the
current implementation uses a three-buffer ring with acquire/release-fence
backpressure. Do not infer an experiment profile from that legacy name alone.

## Holo and Gamescope bring-up

Prepare the disposable Holo userspace and GPU probe:

```sh
android/nova-lab/fetch-holo-rootfs.sh
android/nova-lab/install-holo-packages.sh
android/nova-lab/install-holo-gamescope.sh
android/nova-lab/build-kgsl-turnip.sh
android/nova-lab/deploy-kgsl-turnip.sh
android/nova-lab/build-vulkan-offscreen-probe.sh
android/nova-lab/deploy-vulkan-offscreen-probe.sh
android/nova-lab/deploy-holo-probe.sh
```

The stock Gamescope control is a negative control: it reaches the KGSL Turnip
device, then fails at the unavailable DRM-device identity extension.

Build the opt-in headless path from an explicit Gamescope tree:

```sh
GAMESCOPE_SOURCE=/path/to/gamescope \
  android/nova-lab/build-gamescope-headless.sh
android/nova-lab/build-wayland-shm-control.sh
android/nova-lab/deploy-gamescope-headless-composite-test.sh
android/nova-lab/deploy-gamescope-headless-ahb-test.sh
```

The bounded controls exercise Wayland SHM, Xwayland, and the Android buffer
queue separately. `NOVA_AHB_FRAME_COUNT`, `NOVA_AHB_WIDTH`, and
`NOVA_AHB_HEIGHT` change the bounded experiment dimensions and therefore define
a different profile when changed.

## Bounded acceptance profile

The named profile is `bounded-ahb-1280x960`. It requires 10 frames at 1280×960,
fullscreen 1280×960 presentation, overlay composition, Wayland input, and a
libei-enabled Gamescope artifact. Run it only with a fresh source/build/device
identity:

```sh
GAMESCOPE_HEADLESS_SOURCE=/path/to/gamescope \
NOVA_GAMESCOPE_HEADLESS=/path/to/gamescope-build/src/gamescope \
  android/nova-lab/run-nova-acceptance.sh
```

The harness records the source commit, source status, binary SHA-256, profile,
run ID, and libei marker. It validates a source tree through `git rev-parse`,
so a linked Git worktree is a valid input. Do not reuse a previous run
directory, log tail, socket, screenshot, or readiness line.

## Native Steam probes

Fetch and stage the ARM64 Steam seed and runtime, then run the startup/UI
checks:

```sh
android/nova-lab/fetch-steam-arm64-seed.sh --all
NOVA_STEAM_UID=1000 NOVA_STEAM_GID=1000 \
  android/nova-lab/deploy-steam-arm64-seed.sh
android/nova-lab/deploy-native-steam-smoke-test.sh
android/nova-lab/deploy-native-steam-ui-smoke-test.sh
```

The current SteamUI result is [doc 15](../../docs/15-nova-steam-ui-ahb-smoke.md).
The separate hardware GLX probe remains a negative control and must not be
used to claim hardware CEF for the normal Vulkan-output path:

```sh
android/nova-lab/deploy-native-steam-hardware-probe.sh
```

## Input and manual evidence

The input checks are layered: uinput relay and device discovery, SDL3 event
delivery, Steam D-pad navigation, Android key-event forwarding, and touch via
libei. The most relevant commands are:

```sh
android/nova-lab/build-uinput-gamepad-relay.sh
android/nova-lab/deploy-native-steam-gamepad-input-smoke-test.sh
android/nova-lab/deploy-native-steam-android-input-bridge-smoke-test.sh
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh
```

Use the named manual profile only when a bounded experiment is not sufficient:

```sh
android/nova-lab/deploy-native-steam-manual-session.sh
android/nova-lab/capture-nova-manual-evidence.sh
android/nova-lab/finish-nova-manual-run.sh
```

Manual sessions must be stopped and verified before changing source, patches,
or build artifacts. The process-audit summary in
[`docs/parent-session-process-audit-summary.md`](../../docs/parent-session-process-audit-summary.md)
explains why this serialization is part of the evidence contract.

## Artifacts and cleanup

Useful outputs include:

- `build/root_probe_report.txt` and filtered logcat for Android/root checks;
- `build/device-ahb-bridge-logcat.txt` and the corresponding screenshot;
- Gamescope reports and metadata under the run-specific `build/` directory;
- Steam, Android, Gamescope, X11, CDP, and teardown artifacts under the same
  run ID for manual experiments.

Every run must record the exact Gamescope/APK paths and SHA-256 values, source
tree/build directory, profile, dimensions, composition/input flags, and cleanup
result. A release, diagnostic, or libei-disabled binary is a different
experiment even if its filename is unchanged.

For the current causal ordering and next one-variable scheduler trace, read the
[AHB transport summary](../../docs/nova-ahb-transport-investigation-summary.md),
[doc 70](../../docs/70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md),
[doc 71](../../docs/71-nova-ahb-continuous-repaint-fix-2026-08-09.md), and
[doc 72](../../docs/72-nova-gamescope-present-cadence-experiment-2026-08-09.md).
