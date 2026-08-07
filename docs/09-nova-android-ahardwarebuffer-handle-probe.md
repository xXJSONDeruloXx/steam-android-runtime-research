# Retroid Pocket Nova Android AHardwareBuffer handle probe

Test date: 2026-08-07  
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno  
ADB serial: `675a2365`

This is the Android-side companion to the Linux DMA-BUF result in
[the Holo/Vulkan probe](08-nova-holo-glibc-vulkan-probe.md). It adds a small arm64 NDK
library to the existing lab APK. The native code allocates an Android
`AHardwareBuffer`, writes a marker through the CPU lock API, sends the Android buffer
handle over an `AF_UNIX` socket, receives it back, and verifies the marker. The
round-trip is deliberately a same-process socket-endpoint control: it validates the
Android handle serialization API without claiming that a Linux glibc process can yet
consume an Android buffer handle.

## Reproduction

The checked-in build uses the locally installed Android NDK and packages
`libnovabridge.so` as `arm64-v8a` inside the APK:

```sh
android/nova-lab/build.sh
android/nova-lab/deploy-and-test.sh
```

The automated launcher passes `--ez run_native true`, so the probe runs after the
SurfaceView smoke test. The same operation is available from the APK's **Run native
buffer** button.

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

## What this proves

- The APK can load a native arm64 NDK library on the rooted Nova.
- Android's `AHardwareBuffer` allocation, CPU lock/unlock, and descriptor path work
  with the intended sampled-image/composer usage.
- Android's documented `AHardwareBuffer_sendHandleToUnixSocket` and
  `AHardwareBuffer_recvHandleFromUnixSocket` APIs preserve buffer contents across the
  socket handoff.

## What remains unproven

This does not yet connect the Linux Holo allocation to Android Gralloc. The Linux
probe separately proves that Mesa KGSL Turnip can export/import a DMA-BUF inside the
glibc namespace, while this probe separately proves Android AHardwareBuffer handle
transport. The missing bridge is a real cross-process test in which an Android-side
broker receives a Linux-produced DMA-BUF or AHardwareBuffer-compatible handle, applies
the correct fence/lifetime rules, and presents the resulting image through the app's
Surface/SurfaceControl path.

The next implementation should therefore keep the two controls intact and add the
smallest broker/compositor experiment possible before bringing in gamescope or Steam.
