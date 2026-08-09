# Architecture Decision Matrix

## Comparison

| Path | Steam binary | Root | Display path | Big Picture fit | Current evidence | Recommended role |
|---|---|---:|---|---|---|---|
| GameNative/Winlator | Windows Steam/Wine and Steam APIs | No | Android-owned X11/renderers | Low to medium | Strong product/runtime evidence | Reuse Android plumbing and fallback game runtime |
| Attached Termux:X11 kit | Native ARM64 Linux Steam | Usually no | Termux:X11 over TCP | Low by default; testable with flags | Static kit only; no bundled device proof | Fastest native Steam UI bring-up |
| Holo ARM64 package channel | Native ARM64 client supplied separately by Valve | No by itself | Provides Arch/glibc/graphics/gamescope packages | High as a dependency source | Live aarch64 package/rootfs channel; not a complete client/session | Dependency source and ABI reference |
| Armada | Native ARM64 Steam + ARM Proton; FEX for x86 games | Root for ABL/image installation; non-root Steam user | DRM/KMS gamescope session | High | Repository documents first-run/login path on tested Snapdragon devices | Full-session reference and fastest end-to-end Linux proof |
| PockNix | Native ARM64 Steam + ARM Proton; FEX for x86 games | Root for image build/ABL and system services; non-root `deck` session | DRM/KMS gamescope session | High | Explicit Big Picture launcher, build-time ARM client bake, controller/audio/session plumbing | Closest minimal session recipe to port |
| Holo/chroot + gamescope Android backend | Native ARM64 Linux Steam | Yes | AHardwareBuffer + SurfaceControl | High | Native Steam reaches pre-login Gamepad UI and SteamUI readiness; software CEF, account login, and trusted frame synchronization remain open | Primary Android-managed runtime direction |
| deck-in-a-box | x86 Steam through FEX | No/rootless target | Not completed | High in theory | FEX and Steam bootstrap partial; thread crash | Experimental no-root backend |
| steam-droid | Valve ARM64 Android libraries | No | Android/WebView intended | High in theory | Native libraries load; service boot fails | Reverse-engineering reference, not first product path |

## Decision

The current sources change the order slightly. Armada/PockNix are now the fastest way to prove the
native Steam + gamescope session itself on compatible hardware; the attached kit remains the fastest
way to isolate ordinary ARM64 Steam/CEF problems without DRM/KMS. The Android gamescope bridge should
be tested only after the client/session path is known-good.

The sequence should be:

```text
Valve ARM64 client/runtime channels
  -> Armada/PockNix native Steam + gamescope proof on one supported device
    -> Holo/Arch dependency and package selection
      -> rooted Android-managed Linux userspace
        -> Android AHardwareBuffer/Surface presentation
          -> dedicated Android app shell
            -> rootless user-space process/rootfs experiment
```

This sequence reduces uncertainty in the right order. It separates Steam-client/runtime failures from Android presentation failures.

## Why not start with FEX?

FEX solves architecture translation, but the previous attempt showed that Steam’s low-level thread behavior is sensitive to the proot boundary. It also adds another translation layer if Windows games eventually run through Proton. It remains valuable for rootless experimentation, but it is not the safest path for a Steam-first product.

## Why not start with steam-droid?

The native Android libraries are attractive, but the missing `crashhandler004` path means the public package is not yet a complete bootable client. Reconstructing that dependency and the WebView bridge is a larger unknown than testing a real ARM64 Linux Steam package.

## Why the rooted ARM64 path is the best final target

It preserves the most natural stack:

```text
ARM64 Steam
  -> Linux userspace
    -> gamescope / Wayland compositor
      -> Android SurfaceControl presentation
```

It avoids FEX for the Steam client, avoids pretending Android SurfaceFlinger is DRM/KMS, and uses the presentation path already proven on-device.

The cost is root, device-specific GPU work, and a remaining Android presentation milestone. The new
Armada/PockNix evidence removes much of the native Steam bring-up uncertainty, but it does not remove
the Android kernel/GPU boundary.
