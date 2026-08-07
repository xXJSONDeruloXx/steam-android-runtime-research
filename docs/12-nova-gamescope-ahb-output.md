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

The script builds and installs the Nova lab APK, starts its five-frame
two-buffer AHardwareBuffer test, stages the Gamescope binary and control
client, runs the rooted Holo probe, and checks both sides of the protocol.
Artifacts are saved under `android/nova-lab/build/`:

- `device-gamescope-headless-ahb-report.txt`
- `device-gamescope-headless-ahb-logcat.txt`
- `device-gamescope-headless-ahb-screenshot.png`

Only disposable files below
`/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver` are staged on the
device. Android partitions, boot images, and the global root/SU policy are not
modified.

## Implemented handoff

The Android app offers two `AHardwareBuffer` allocations as DMA-BUF handles
on `nova-lab-ahb-double-buffer.sock.0` and `.1`. Gamescope:

1. imports both handles as output `CVulkanTexture` objects;
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

## Nova evidence

The accepted run produced five Wayland frames and five Android output
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

This proves the first complete measured path:

```text
Wayland SHM surface
  -> Gamescope layer list
  -> Vulkan composite into imported Android AHardwareBuffer
  -> Linux acquire fence
  -> Android SurfaceControl presentation
  -> Android release fence
  -> safe two-buffer reuse
```

The saved screenshot is a post-run Android display capture, not a frame-locked
capture of the five 64x64 compositor images. It is therefore retained as a
device artifact but is not used as visual proof of the Gamescope pixels.

## Remaining boundary

This is still not a Steam session. The control client is a 64x64 `wl_shm`
producer and the run is intentionally limited to five frames. The Vulkan WSI
negative control from doc 11 remains valid: the Holo Turnip ICD lacks
`VK_KHR_surface`, so a normal `vkcube --wsi wayland` swapchain cannot be
the next client.

The next experiments are to sustain the imported output at a real display
size, preserve the queue beyond five frames, and then replace the control
client with a persistent Wayland/Xwayland session suitable for the native ARM64
Steam client. Input, lifecycle cleanup, and the direct asynchronous fence path
remain separate acceptance gates.
