# Steam Android Runtime Research

Private evidence archive for building an Android app with a Linux runtime and a Steam/gamepad-first experience, rather than a Windows/Wine container as the primary product model.

Status: evidence gathered through 2026-08-07.

## Bottom line

No previous attempt has reached the actual Steam login/library or Big Picture/Gamepad UI on Android.

The useful results are split across several projects:

- [GameNative](https://github.com/xXJSONDeruloXx/GameNative) proves the Android product plumbing: storage, downloads, Steam data, containers, input, lifecycle, and practical rendering.
- [deck-in-a-box](https://github.com/xXJSONDeruloXx/deck-in-a-box) proves that real FEX can execute x86 code inside an Android-managed Linux environment, but Steam crashes in the FEX+proot thread path.
- [steam-droid](https://github.com/xXJSONDeruloXx/steam-droid) proves Valve's ARM64 Android Steam libraries can be loaded, but the public package is not sufficient to boot the native service.
- [steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings) proves the strongest display path so far: ARM64 Linux userspace, KGSL Turnip, AHardwareBuffer exchange, SurfaceControl presentation, and a gamescope Android backend capable of presenting 600 compositor frames.
- The attached [Termux:X11 kit assessment](docs/02-termux-x11-kit-assessment.md) is a useful simpler bring-up path for normal ARM64 Steam desktop mode, but its own README explicitly excludes Gamescope and Steam Deck Big Picture.

## Recommended direction

Use a layered strategy:

1. Reuse GameNative's Android-side lifecycle, storage, download, controller, and session-management patterns.
2. Prove native ARM64 Steam first through the attached Termux:X11 kit. This is the fastest way to answer whether the ARM64 Steam client and `steamwebhelper` can render on the target device.
3. Move the proven client into the rooted Holo/chroot + gamescope path from `steam-arm-findings`.
4. Use the Android AHardwareBuffer/SurfaceControl backend for the final fullscreen presentation path.
5. Keep FEX as an experimental no-root backend, not the first product-critical runtime.

The first meaningful acceptance test is: native ARM64 Steam reaches its login or Gamepad UI screen, with hardware `steamwebhelper` rendering and controller input, on one known Snapdragon/Adreno device.

## Documents

- [Prior work evidence](docs/01-prior-work-evidence.md)
- [Termux:X11 kit assessment](docs/02-termux-x11-kit-assessment.md)
- [Architecture decision matrix](docs/03-decision-matrix.md)
- [Open questions and next experiments](docs/04-open-questions.md)

## Evidence standard

“Proven” means the repository contains concrete on-device output, test artifacts, or a documented build/run result. “Partial” means a lower-level prerequisite works but the target milestone does not. “Claimed/untested” means the artifact describes a path but does not include enough device evidence to verify it independently.

## Scope note

This archive records technical evidence, not a redistribution of Valve runtime binaries. The attached ZIP was inspected but is not copied into this repository. Its SHA-256 and original workspace path are recorded in the kit assessment.
