# Prior Work Evidence

This document consolidates the relevant GitHub history around Android PC-game runtimes, Linux containers, native Steam, FEX, and gamepad-first presentation.

## Timeline

| Period | Repository or work | Evidence level | Main result |
|---|---|---|---|
| 2025-07 to 2026-08 | [GameNative](https://github.com/xXJSONDeruloXx/GameNative) | Proven/partial | Mature Android/Wine container and Steam data plumbing; Bionic containers, ARM64 Proton, controllers, and hardware rendering work. |
| 2026-04-10 | [GN-Lime](https://github.com/xXJSONDeruloXx/GN-Lime) | Packaging | Side-by-side rebrand and runtime mirror; no fundamental runtime architecture change. |
| 2026-04-18 | [deck-in-a-box](https://github.com/xXJSONDeruloXx/deck-in-a-box) | Partial, on-device | Real FEX x86-64 execution works; Steam x86-32 bootstrap initializes, then crashes in thread primitives. |
| 2026-04-19 | [steam-droid](https://github.com/xXJSONDeruloXx/steam-droid) | Partial, on-device | Valve ARM64 Android libraries load; `SteamService_StartThread()` does not complete. |
| 2026-04-26 | [libsteambootstrap](https://github.com/xXJSONDeruloXx/libsteambootstrap) | Reverse-engineering | Reconstructed GameNative-related Steam IPC/bootstrap helper; useful for Proton game integration, not a full client. |
| 2026-06-15 | [steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings) | Strong partial, on-device | Rooted ARM64 Linux rootfs, KGSL Turnip, Android buffer bridge, SurfaceControl, gamescope backend, and 600-frame compositor proof. |
| 2026-06-22 | [GameNative SurfaceFlinger renderer](https://github.com/xXJSONDeruloXx/GameNative/commit/f9cbe32) | Proven/partial | Direct Android SurfaceFlinger presentation works, but with documented X11/compositor limitations. |

## GameNative and Winlator lineage

The strongest already-working layer is the Android application layer.

The [initial Bionic work](https://github.com/xXJSONDeruloXx/GameNative/commit/20ebeaf) records:

- Bionic containers booting and switching between Bionic and glibc variants.
- ARM64EC/FEX-related paths.
- GPU rendering for Bionic x86-64.
- ARM64 Proton through `LD_PRELOAD`.
- SDL controllers.
- First-time container unpacking.
- PulseAudio becoming the practical default after ALSA problems.

The [real Steam milestone](https://github.com/xXJSONDeruloXx/GameNative/commit/03909c3) added the ability to launch Steam inside containers and launch games through the Steam app. Later commits continued improving “Bionic Steam,” networking, workshop handling, storage, and input.

This is proven product infrastructure, but it is not the desired product center of gravity. The app remains a custom Android launcher around Wine/Proton containers; the Linux desktop Steam session is not the primary shell.

The [SurfaceFlinger renderer](https://github.com/xXJSONDeruloXx/GameNative/commit/f9cbe32) is useful prior art for direct Android presentation. Its own commit records important limitations: X11 geometry mismatches, no shader path, color shifts, incomplete desktop backgrounds, tearing under some frame limiting, and cursor visibility problems.

## deck-in-a-box: Linux runtime plus FEX

[deck-in-a-box](https://github.com/xXJSONDeruloXx/deck-in-a-box) has the closest product thesis to this research archive:

```text
Android shell
  -> app-managed glibc Linux runtime
    -> FEX on ARM64
      -> x86/x86-64 Steam
        -> eventual Steam-centric/gamepad UI
```

### What worked

- Android app and runtime staging logic built successfully.
- The initial fake FEX archive was replaced with a real ARM64 FEX package.
- proot was used to bridge Android Bionic and glibc Linux.
- A real FEX interpreter ran x86-64 Linux code on Android ARM64.
- `uname -m` returned `x86_64` from the emulated guest.
- Steam’s x86-32 bootstrap reached `CProcessEnvironmentManager` initialization.

The key result is documented in the [FEX/Steam loading commit](https://github.com/xXJSONDeruloXx/deck-in-a-box/commit/b6a0a4e).

### What failed

- The original bundled `fexcore` asset contained Windows PE DLLs, not a native Linux FEX interpreter.
- Android could not directly launch the glibc-linked FEX binary.
- A real ARM64 host rootfs and proot path were required.
- Steam crashed at `threadtools.cpp:2341` with a “Function not implemented” assertion.
- The journal attributes this to missing thread/futex/clone behavior in the FEX+proot environment.
- Steam Runtime integration, display, input, and the login/Big Picture UI were not reached.

### Lesson

FEX is viable as an execution primitive, but “FEX runs one x86 binary” is not equivalent to “Steam and Proton run reliably inside an Android app sandbox.” The proot/syscall boundary is the major risk.

## steam-droid: native Android Steam libraries

[steam-droid](https://github.com/xXJSONDeruloXx/steam-droid) investigated Valve’s ARM64 Android package directly.

### What worked

- The public package’s `libsteamclient.so`, `steamservice.so`, networking, tier0, and vstdlib libraries were staged reproducibly.
- The Android Gradle project built and packaged them.
- `steamservice.so` loaded by absolute path on real ARM64 devices.
- JNI symbol resolution worked.
- Moving service startup off the main thread removed the initial Android ANR problem.
- The UI analysis established that Steam’s client UI is a React/webpack browser application with a gamepad/mobile mode.

### What failed

`SteamService_StartThread()` still returned false. Live debugging found two separate issues:

1. Some devices entered an OpenSSL ARM SHA-512 capability probe and executed unsupported instructions. `OPENSSL_armcap=0` suppressed that path but did not finish startup.
2. Startup then depended on `crashhandler.so` and the `crashhandler004` interface. The required Android crashhandler was not present in the public package, and simple stubs were insufficient.

The [boot-debug journal](https://github.com/xXJSONDeruloXx/steam-droid/blob/main/JOURNAL-2026-04-19-boot-debug.md) is the strongest evidence here.

The repo’s earlier estimate that only a small amount of integration remained was not borne out by device bring-up. Static binary analysis found a lot, but the missing runtime dependency was foundational.

## libsteambootstrap

[libsteambootstrap](https://github.com/xXJSONDeruloXx/libsteambootstrap) reconstructed a prebuilt Android library used in the GameNative family.

It bootstraps Linux-side `libsteamclient.so` so Proton’s `lsteamclient.dll` can communicate with Steam IPC sockets. It shows that a native Android process can help Windows games access Steam services, but it does not provide the Steam browser UI, desktop session, or Big Picture shell.

## steam-arm-findings: rooted ARM64 Linux plus gamescope

[steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings) is the strongest match for the desired runtime semantics because it avoids x86 translation for the Steam client itself.

### What worked

- A rooted AYN Thor/Snapdragon device was characterized.
- A Holo ARM64 Linux rootfs was deployed into a rooted Android chroot.
- Stock Holo Turnip failed to enumerate the Android KGSL GPU, but a custom Mesa build with `freedreno-kmds=kgsl` found the Adreno 740.
- Abstract Unix sockets, `SCM_RIGHTS`, dma-buf allocation, KGSL import, and Vulkan external-memory paths worked.
- Android allocated displayable `AHardwareBuffer`s, sent them into the chroot, and custom Turnip rendered into them.
- Android presented the buffers through `SurfaceControl`.
- A three-buffer pool presented 180 frames with completion and fence callbacks.
- A patched gamescope Android backend initialized KGSL Turnip, started nested Wayland/Xwayland, imported persistent AHardwareBuffers, and presented 600 `vkcube` frames.

See the [600-frame gamescope result](https://github.com/xXJSONDeruloXx/steam-arm-findings/commit/21be9ea) and the [Android backend options](https://github.com/xXJSONDeruloXx/steam-arm-findings/blob/main/docs/gamescope-android-backend-options.md).

### What remains

- Stock gamescope assumes DRM/KMS and fails when KGSL Turnip does not expose `VK_EXT_physical_device_drm`.
- The custom Android backend still needs proper acquire/release fence backpressure.
- Input forwarding is not complete.
- Xwayland glamor falls back to software because Android/KGSL does not provide the expected DRM/GBM path.
- The recorded client was `vkcube`; no Steam login, library, or Big Picture UI result is recorded.
- The path begins with root and is device/GPU-specific.

### Lesson

This is currently the best foundation for a Steam-first product, but only after the Steam client itself is brought up in the same environment.

## Adjacent experiments

- [OMFG Android POC](https://github.com/xXJSONDeruloXx/omfg-android-poc) showed that MediaProjection capture and CPU frame synthesis are not a substitute for an in-process compositor or a Linux-to-Android presentation bridge.
- [GN-Lime](https://github.com/xXJSONDeruloXx/GN-Lime) improved side-by-side packaging, runtime mirrors, and release flow, but did not change the Windows/Wine-centered architecture.
- [CellarKit-iOS](https://github.com/xXJSONDeruloXx/CellarKit-iOS) is useful app-shell and session-model prior art, but its target is iOS rather than Android.
