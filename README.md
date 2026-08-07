# Steam Android Runtime Research

Private evidence archive for building an Android app with a Linux runtime and a Steam/gamepad-first experience, rather than a Windows/Wine container as the primary product model.

Status: evidence gathered through 2026-08-07.

## Bottom line

No previous Android-app attempt has reached the actual Steam login/library or Big Picture/Gamepad UI
on Android. The current ARM handheld Linux ecosystem has moved further than the earlier experiments:
Valve's ARM64 client and Steam runtime are directly reachable from live distribution endpoints, and
Armada/PockNix document complete native-ARM64 Steam + gamescope sessions on supported Snapdragon
handhelds.

The useful results are split across several projects:

- [GameNative](https://github.com/xXJSONDeruloXx/GameNative) proves the Android product plumbing: storage, downloads, Steam data, containers, input, lifecycle, and practical rendering.
- [deck-in-a-box](https://github.com/xXJSONDeruloXx/deck-in-a-box) proves that real FEX can execute x86 code inside an Android-managed Linux environment, but Steam crashes in the FEX+proot thread path.
- [steam-droid](https://github.com/xXJSONDeruloXx/steam-droid) proves Valve's ARM64 Android Steam libraries can be loaded, but the public package is not sufficient to boot the native service.
- [steam-arm-findings](https://github.com/xXJSONDeruloXx/steam-arm-findings) proves the strongest display path so far: ARM64 Linux userspace, KGSL Turnip, AHardwareBuffer exchange, SurfaceControl presentation, and a gamescope Android backend capable of presenting 600 compositor frames.
- The attached [Termux:X11 kit assessment](docs/02-termux-x11-kit-assessment.md) is a useful simpler bring-up path for normal ARM64 Steam desktop mode, but its own README explicitly excludes Gamescope and Steam Deck Big Picture.
- [Current ARM64 Steam research](docs/05-current-arm64-steam-research.md) records the live Valve endpoints, Holo's ARM64 package/rootfs channel, and the current Armada/PockNix session implementations.
- [Android/Linux/gamescope roadmap](docs/06-android-linux-gamescope-roadmap.md) turns the evidence into a rooted MVP and a staged rootless target.
- [Nova rooted bridge lab](docs/07-nova-rooted-bridge-smoke-test.md) records the first real Android-app Surface/HardwareBuffer and rooted chroot smoke test.
- [Nova Holo glibc/Vulkan probe](docs/08-nova-holo-glibc-vulkan-probe.md) records native ARM64 glibc success, the stock-Holo control failure, a working KGSL Turnip/offscreen command path, and a verified Vulkan DMA-BUF export/import handoff.
- [Nova Android AHardwareBuffer probe](docs/09-nova-android-ahardwarebuffer-handle-probe.md) records Android Vulkan import, a bidirectional Android-to-Holo DMA-BUF/GPU handoff, export-before-wait acquire-fence ordering, and a five-frame two-buffer SurfaceControl loop with release-fence backpressure.
- [Nova stock gamescope control](docs/10-nova-stock-gamescope-control.md) records the first gamescope run on the same KGSL Vulkan path: stock gamescope reaches the Adreno device, then stops because its DRM-device discovery contract is not available.
- [Nova headless gamescope seam](docs/11-nova-headless-gamescope-seam.md) records a patched ARM64 headless gamescope compositor crossing that DRM-identity boundary, compositing 298 Wayland SHM frames on the Nova, and leaving persistent Android output as the next seam.
- [Nova Gamescope Android output](docs/12-nova-gamescope-ahb-output.md) records the first five-frame imported AHardwareBuffer output path from Gamescope through Android SurfaceControl, including acquire and release fence handoff.

## Recommended direction

Use a layered strategy:

1. Reuse GameNative's Android-side lifecycle, storage, download, controller, and session-management patterns.
2. Use Armada/PockNix as the current reference for the Steam Deck-like session: native ARM64 Steam, gamescope, Xwayland, input, audio, Proton, and FEX for x86 games.
3. Use Holo's aarch64 Arch package channel for compatible glibc/graphics/gamescope dependencies, while fetching the native Steam client from Valve's client/runtime channels.
4. Prove the first Android product path with root: app-owned Linux userspace plus the existing AHardwareBuffer/SurfaceControl gamescope direction from `steam-arm-findings`.
5. Keep the Termux:X11 kit as a desktop-mode diagnostic/fallback path, and keep FEX as the game-compatibility layer—not the native Steam-client runtime.
6. Remove root only after the session, graphics, input, and lifecycle contracts are independently passing.

The first meaningful acceptance test is: native ARM64 Steam reaches its login or Gamepad UI screen,
with hardware `steamwebhelper` rendering and controller input, on one known Snapdragon/Adreno device.
The first Android-app acceptance test adds: the Android app starts/stops that Linux session and presents
the gamescope frames on its own surface.

## Documents

- [Prior work evidence](docs/01-prior-work-evidence.md)
- [Termux:X11 kit assessment](docs/02-termux-x11-kit-assessment.md)
- [Architecture decision matrix](docs/03-decision-matrix.md)
- [Open questions and next experiments](docs/04-open-questions.md)
- [Current ARM64 Steam research](docs/05-current-arm64-steam-research.md)
- [Android/Linux/gamescope roadmap](docs/06-android-linux-gamescope-roadmap.md)
- [Nova rooted bridge smoke test](docs/07-nova-rooted-bridge-smoke-test.md)
- [Nova Holo glibc and Vulkan probe](docs/08-nova-holo-glibc-vulkan-probe.md)
- [Nova Android AHardwareBuffer handle probe](docs/09-nova-android-ahardwarebuffer-handle-probe.md)
- [Nova stock gamescope control](docs/10-nova-stock-gamescope-control.md)
- [Nova headless gamescope seam](docs/11-nova-headless-gamescope-seam.md)
- [Nova Gamescope Android AHardwareBuffer output](docs/12-nova-gamescope-ahb-output.md)
- [Retroid Pocket Nova flashing kit](tools/retroid-pocket-nova/README.md)

## Evidence standard

“Proven” means the repository contains concrete on-device output, test artifacts, or a documented build/run result. “Partial” means a lower-level prerequisite works but the target milestone does not. “Claimed/untested” means the artifact describes a path but does not include enough device evidence to verify it independently.

## Scope note

This archive records technical evidence, not a redistribution of Valve runtime binaries. The attached ZIP was inspected but is not copied into this repository. Its SHA-256 and original workspace path are recorded in the kit assessment.
