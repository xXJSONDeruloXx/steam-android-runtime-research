# Nova Gamescope Android AHardwareBuffer output

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`
Gamescope source: local `gamescope-valve` commit `fb9f84ee247a1f02b1a132da60e94585db84bf61`

This is the first experiment that connects the patched headless Gamescope
`Present()` seam to the Android app's persistent AHardwareBuffer queue. It is
the next step after [doc 11](11-nova-headless-gamescope-seam.md), which proved
Wayland surface ingestion and Vulkan compositor submission but kept the result
inside Gamescope.

The output path is opt-in through `NOVA_AHB_OUTPUT_SOCKET`. The normal
headless control remains unchanged when that variable is unset.

## Reproduction

Build the checked-in three-patch Gamescope stack and the ARM64 Wayland control
client:

```sh
GAMESCOPE_SOURCE=/path/to/gamescope \
  android/nova-lab/build-gamescope-headless.sh

android/nova-lab/build-wayland-shm-control.sh
```

With the Holo rootfs, package closure, and KGSL Turnip deployment already
prepared, run the end-to-end acceptance test:

```sh
INSTALL_HOLO_GAMESCOPE=0 \
  android/nova-lab/deploy-gamescope-headless-ahb-test.sh
```

The script builds and installs the Nova lab APK, starts its configurable
three-buffer AHardwareBuffer test (60 frames by default), stages the Gamescope
binary and control client, runs the rooted Holo probe, and checks both sides of
the protocol.
Artifacts are saved under `android/nova-lab/build/`:

- `device-gamescope-headless-ahb-report.txt`
- `device-gamescope-headless-ahb-logcat.txt`
- `device-gamescope-headless-ahb-metadata.txt` (binary hash and mode identity)
- `device-gamescope-headless-ahb-screenshot.png`

Only disposable files below
`/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver` are staged on the
device. Android partitions, boot images, and the global root/SU policy are not
modified.

The frame count and output dimensions are configurable for bounded experiments:

```sh
INSTALL_HOLO_GAMESCOPE=0 \
  NOVA_AHB_FRAME_COUNT=30 NOVA_AHB_WIDTH=960 NOVA_AHB_HEIGHT=540 \
  android/nova-lab/deploy-gamescope-headless-ahb-test.sh
```

The dimensions are carried through the Android `AHardwareBuffer` allocation and
`SurfaceControl` geometry, Gamescope's DMA-BUF import and stride, and the
headless control client's output and nested sizes. The default remains 64x64 so
the short control path stays cheap to reproduce.

## Implemented handoff

The Android app offers three `AHardwareBuffer` allocations as DMA-BUF handles
on `nova-lab-ahb-double-buffer.sock.0`, `.1`, and `.2`. Gamescope:

1. imports all three handles as output `CVulkanTexture` objects;
2. composites each Wayland frame into the next buffer;
3. waits for the compositor submission to complete;
4. exports a signaled Linux sync FD and sends the existing Android bridge
   acknowledgement plus that FD;
5. waits for Android's returned SurfaceControl release fence before reusing
   the buffer.

The app passes each Linux acquire fence to its SurfaceControl transaction and
returns the previous buffer's release fence over the same socket. This reuses
the already-proven Android-side ownership contract rather than introducing a
second display protocol.

The first fence implementation is deliberately synchronous. The exported
acquire FD is a signaled semaphore submitted after `vulkan_wait()`; it is a
valid Android handoff fence, but it is not yet the compositor submission's
native asynchronous timeline. The next optimization is to preserve the
compositor signal directly and remove this wait/empty-submit boundary.

## Historical two-buffer baseline

The first runs recorded below used the original two-buffer implementation. They
remain useful evidence for the protocol shape, but are not the current queue
contract; current deploys explicitly report three imported buffers.

## Nova evidence

The initial bounded run produced five Wayland frames and five Android output
compositions:

```text
vulkaninfo_status=0
[headless] Android AHardwareBuffer output imported: 2 x 64x64 RGBA
Running compositor on wayland display 'gamescope-0'
wayland_connect=pass socket=gamescope-0
android_ahb_composite_frame=1 layers=1 async=0
android_ahb_composite_frame=2 layers=1 async=0
android_ahb_composite_frame=3 layers=1 async=0
wayland_shm_frames=5
offscreen_probe_status=0
probe_status=0
```

The Android app log records the other half of the contract:

```text
ahb_double_buffer_frame=0 ... linux_acquire_fence=pass ... fence_fd=received
surface_frame_complete=pass ... previous_release_fence=0
ahb_double_buffer_frame=1 ... previous_release_fence=1 ... release_1 sent buffer=0
ahb_double_buffer_frame=2 ... release_2 sent buffer=1
ahb_double_buffer_frame=3 ... release_3 sent buffer=0
ahb_double_buffer_frame=4 ... release_4 sent buffer=1
ahb_double_buffer_frames=5 releases=4
ahb_double_buffer=pass
```

The follow-up sustained run used the same 64x64 buffers for 60 frames. It
completed with no dropped acknowledgements or release-fence returns:

```text
wayland_shm_frames=60
android_ahb_composite_frame=60 layers=1 async=0
ahb_double_buffer_frames=60 releases=59
ahb_double_buffer=pass
dma_buf_double_buffer_summary ahb_double_buffer_frames=60 releases=59 ahb_double_buffer=pass
```

The 60-frame run also recorded 60
`surface_frame_complete=pass` callbacks and 59
`ahb_double_buffer_release_N=sent` messages. This is the first evidence that
the imported output queue remains stable beyond the initial handshake. The
SurfaceControl latch timestamps spanned 982,498,177 ns across the run
(approximately 16.65 ms per frame).

The display-size acceptance run used 30 frames at 960x540. It completed with
the same two-buffer contract:

```text
[headless] Android AHardwareBuffer output imported: 2 x 960x540 RGBA
wayland_shm_frames=30
offscreen_probe_status=0
probe_status=0
ahb_double_buffer_size=960x540
ahb_double_buffer_frames=30 releases=29
dma_buf_double_buffer_summary ahb_double_buffer_frames=30 releases=29 ahb_double_buffer=pass
```

The Android log contained 30 `surface_frame_complete=pass` callbacks, 30
`linux_acquire_fence=pass` acknowledgements, and 29 sent release fences. The
SurfaceControl latch span was 491,089,479 ns, or approximately 16.93 ms per
frame. The saved device screenshot visibly contains the scaled color field in
the Android child surface.

This run also exposed and fixed a final-release teardown race. The Wayland SHM
control client used to exit as soon as the final frame callback arrived, which
could close Gamescope's Android sockets before Android completed its last
`SurfaceControl` transaction. It now keeps the Wayland connection alive for a
bounded 1,000 ms release-drain window after the final callback. The 960x540 run
and the 64x64/60-frame regression both completed their final release fence.

This proved the first complete measured path:

```text
Wayland SHM surface
  -> Gamescope layer list
  -> Vulkan composite into imported Android AHardwareBuffer
  -> Linux acquire fence
  -> Android SurfaceControl presentation
  -> Android release fence
  -> safe two-buffer reuse (historical baseline)
```

The saved screenshot is a post-run Android display capture, not a frame-locked
capture of the short 64x64 compositor run. It is therefore retained as a
device artifact but is not used as visual proof of the Gamescope pixels.

## Debug-only frame-order and pacing diagnostic

The bounded frame counts, SurfaceControl latch spans, acquire fences, and
release fences prove successful handoff and safe queue reuse. They do not
yet prove that the Android display presents every frame in monotonically
increasing order, that frames are not repeated or dropped, or that production
is locked to the panel's actual vsync cadence. An `adb screencap` is also an
arbitrary-time capture and is not frame-locked evidence.

The upcoming diagnostic path should be enabled only for investigation and
should stamp every submitted frame with a monotonically increasing `frame_id`
and producer timestamp. The trace should correlate:

```text
frame_id -> Gamescope submit -> Android latch -> present -> release
```

It should run in a continuous session long enough to distinguish repeats,
drops, and reordering, while recording the AHardwareBuffer index and the
associated acquire/release fence result. The result must drive a concrete
classification:

- decreasing frame IDs indicate transaction ordering, buffer lifetime, or
  premature buffer reuse and must be fixed;
- monotonic IDs with repeats or gaps indicate a pacing/vsync or producer-load
  issue and require an explicit policy;
- monotonic IDs in the bridge trace but a visually inconsistent screenshot
  indicate that the capture method is not measuring panel presentation.

Keep this instrumentation behind a debug flag and default it off after the
root cause is understood; retain the final measurements and any pacing fix as
the permanent acceptance evidence.

## Current three-buffer and fullscreen gate

On 2026-08-08, a clean 1280x960 run with composer-overlay usage enabled
(`NOVA_FORCE_GPU_COMPOSITION=0`) completed the current three-buffer contract:

```text
Android AHardwareBuffer output imported: 3 x 1280x960 RGBA
ahb_double_buffer_frames=10 releases=9
ahb_double_buffer=pass
android_ahb_target_reached=10
nova_runtime_cleanup=pass ... remaining=
```

The full-resolution Android Surface is therefore the device's native 4:3
geometry rather than a stretched 16:9 target. The `force_gpu_composition=0`
mode retains the Android composer-overlay usage bit required by the
`ASurfaceTransaction_setBuffer()` path; the rejected back-pressure experiment
and the older force-GPU mode remain separate diagnostic configurations.

The long-lived session is not yet promoted to a release gate. A historical
libei-enabled binary sustained at least 120 sampled compositor frames (and the
later run crossed 480), while the current locally selected binary reports that
it was built without libei and stalled at the three-buffer release boundary.
The harness now records the exact binary SHA-256 and libei build marker in the
metadata artifact. Build the current libei-enabled artifact and repeat the
same clean 1280x960 session before attributing that difference to the Android
queue itself.

## Remaining boundary

This is still not a Steam session. The bounded `wl_shm` client has now been
supplemented by the Xwayland/animated-X11 proof in [doc 13](13-nova-xwayland-ahb-output.md),
which passes the same 960x540 Android fence path. The Vulkan WSI negative
control from doc 11 remains valid: the Holo Turnip ICD lacks `VK_KHR_surface`,
so a normal `vkcube --wsi wayland` swapchain cannot be the next client. The
actual native Steam Xwayland workload now reaches the update UI and produces
bounded AHardwareBuffer frames; `steamwebhelper` and a persistent Steam frame
remain untested.

The next experiments are to keep the persistent Xwayland session while fixing
the native Steam bootstrap/child-process lifecycle, remove the synchronous
wait/empty-submit fence boundary, and add input and lifecycle supervision. The
actual Steam UI remains a separate acceptance gate.
