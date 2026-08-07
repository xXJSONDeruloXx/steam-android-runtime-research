# Retroid Pocket Nova Android AHardwareBuffer handle probe

Test date: 2026-08-07  
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno  
ADB serial: `675a2365`

This is the Android-side companion to the Linux DMA-BUF result in
[the Holo/Vulkan probe](08-nova-holo-glibc-vulkan-probe.md). It adds a small arm64 NDK
library to the existing lab APK. The probe now covers three layers: Android
`AHardwareBuffer` handle transport, Android system Vulkan import/render, and a real
cross-process Android-to-Holo DMA-BUF handoff. The final handoff keeps a marker written
by Android, imports the matching raw `/dmabuf:` FD in the Holo glibc process, writes a
second marker with Linux Turnip, and reads that second marker back through Android's
buffer lock API.

## Reproduction

The checked-in build uses the locally installed Android NDK and packages
`libnovabridge.so` as `arm64-v8a` inside the APK:

```sh
android/nova-lab/build.sh
android/nova-lab/deploy-and-test.sh
android/nova-lab/deploy-ahb-bridge-test.sh
```

The automated launcher passes `--ez run_native true` and
`--ez run_android_vulkan true`, so both Android controls run after the SurfaceView
smoke test. The same operations are available from the APK's **Run native buffer** and
**Run Android Vulkan** buttons. The bridge script starts the APK's **Run Linux bridge**
server, binds the app's private files directory into the Holo namespace, and launches
the checked-in Linux Vulkan probe with the socket path.

## Device result

The Nova accepted the requested 64x64 RGBA8888 allocation with CPU read/write,
GPU-sampled-image, and composer-overlay usage:

```text
native_probe_version=1
ahardwarebuffer.supported=1 usage=0x933
ahardwarebuffer.allocate_status=0
ahardwarebuffer.desc=64x64 layers=1 format=1 usage=0x933
ahardwarebuffer.lock_write_status=0
ahardwarebuffer.unlock_write_status=0
socketpair_status=0
ahardwarebuffer.send_handle_status=0
ahardwarebuffer.recv_handle_status=0
ahardwarebuffer.lock_read_status=0
ahardwarebuffer.received_value=0x4e4f5641
ahardwarebuffer_handle_roundtrip=pass
```

The same run also retained the earlier Android app evidence: `120/120` SurfaceView
frames posted at approximately `53.6 fps`, and the Java `HardwareBuffer` control
created its 64x64 RGBA8888 allocation.

## Android system Vulkan result

The Nova's Android Vulkan driver imported the app-owned AHardwareBuffer as an image,
cleared it on the Adreno 740, and exposed the expected bytes to the Android CPU lock
API:

```text
device=Adreno (TM) 740
extension.VK_ANDROID_external_memory_android_hardware_buffer=present
extension.VK_KHR_external_memory=present
extension.VK_KHR_external_memory_fd=present
extension.VK_EXT_external_memory_dma_buf=missing
vkGetAndroidHardwareBufferProperties_status=0 allocation_size=16384 memory_type_bits=0x12
vkCreateImage_status=0
vkAllocateMemory_import_status=0 memory_type_index=1
vkQueueSubmit_status=0
vulkan_clear_pixel=4080c0ff
android_vulkan_ahardwarebuffer=pass
```

The missing Android `VK_EXT_external_memory_dma_buf` extension is important: the
Android path is not importing the Linux FD through an Android Vulkan DMA-BUF extension.
The next section validates the lower-level raw FD route directly through the shared
KGSL allocation.

## Cross-process Linux bridge result

The Android bridge wrote `0x4e4f5641` into a 64x64 RGBA8888 AHardwareBuffer and sent
its native handle to the Holo-side receiver. The receiver saw two raw DMA-BUF FDs and
the first one imported successfully into Mesa KGSL Turnip:

```text
mount./data/local/tmp/nova-holo-rootfs/run/nova-lab-app=pass
ahb_bridge_recv_bytes=148 ahb_bridge_fd_count=2
ahb_bridge_vkCreateBuffer_status=0
ahb_bridge_fd_0_allocate_status=0
ahb_bridge_fd_0_bind_status=0
ahb_bridge_fd_0_map_status=0
ahb_bridge_fd_0_value=0x4e4f5641
```

The Linux process then submitted `vkCmdFillBuffer` to that imported allocation,
waited on a Vulkan fence, and wrote `0xb16b00b5`. The Android process read the new
value from the original AHardwareBuffer after receiving the acknowledgement:

```text
ahb_bridge_linux_gpu_status=0
ahb_bridge_linux_gpu_value=0xb16b00b5
ahb_bridge=pass
ahb_bridge_status=0
bridge_ack_bytes=39 ack=linux_import=pass linux_gpu_write=pass
ahardwarebuffer.lock_after_linux_status=0
ahardwarebuffer.value_after_linux=0xb16b00b5
ahb_linux_gpu_write=pass
ahb_linux_bridge=pass
```

## What this proves

- The APK can load a native arm64 NDK library on the rooted Nova.
- Android's `AHardwareBuffer` allocation, CPU lock/unlock, and descriptor path work
  with the intended sampled-image/composer usage.
- Android's documented `AHardwareBuffer_sendHandleToUnixSocket` and
  `AHardwareBuffer_recvHandleFromUnixSocket` APIs preserve buffer contents across the
  socket handoff.
- Android's system Vulkan driver can import an AHardwareBuffer image, execute a GPU
  clear, and expose the result through Android's CPU lock API.
- A raw AHardwareBuffer handle can cross the Android-to-Holo Unix socket boundary as
  DMA-BUF FDs; the Holo glibc process can import the matching FD with KGSL Turnip.
- Linux Turnip can write the imported Android allocation and Android can observe the
  result, proving the bidirectional memory/GPU handoff needed before compositor work.

## What remains unproven

This still does not present a Linux-rendered image through the app's `Surface` or
SurfaceControl. The bridge uses CPU-written/CPU-read markers and a Vulkan buffer, not
an image with Android release fences, frame pacing, or compositor ownership. It also
does not prove Wayland, gamescope, Xwayland, SteamRT3C, the native Steam client, input,
audio, or lifecycle recovery.

The next implementation should turn this proven shared allocation into a visible
image path: use an exportable/importable RGBA image, carry acquire/release fences, and
present one Linux-rendered frame through the existing app Surface before adding a
headless compositor or gamescope.
