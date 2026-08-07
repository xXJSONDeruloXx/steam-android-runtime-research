# Architecture Decision Matrix

## Comparison

| Path | Steam binary | Root | Display path | Big Picture fit | Current evidence | Recommended role |
|---|---|---:|---|---|---|---|
| GameNative/Winlator | Windows Steam/Wine and Steam APIs | No | Android-owned X11/renderers | Low to medium | Strong product/runtime evidence | Reuse Android plumbing and fallback game runtime |
| Attached Termux:X11 kit | Native ARM64 Linux Steam | Usually no | Termux:X11 over TCP | Low by default; testable with flags | Static kit only; no bundled device proof | Fastest native Steam UI bring-up |
| Holo/chroot + gamescope Android backend | Native ARM64 Linux Steam | Yes | AHardwareBuffer + SurfaceControl | High | 600 compositor frames proven; Steam not yet booted | Primary final runtime direction |
| deck-in-a-box | x86 Steam through FEX | No/rootless target | Not completed | High in theory | FEX and Steam bootstrap partial; thread crash | Experimental no-root backend |
| steam-droid | Valve ARM64 Android libraries | No | Android/WebView intended | High in theory | Native libraries load; service boot fails | Reverse-engineering reference, not first product path |

## Decision

The attached kit should be used as a bring-up accelerator before investing further in the custom Android gamescope backend.

The sequence should be:

```text
Attached Termux:X11 kit
  -> native ARM64 Steam UI proof
    -> optional -gamepadui/-bigpicture proof
      -> Gamescope around the same ARM64 client
        -> Android AHardwareBuffer/SurfaceControl backend
          -> dedicated Android app shell
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

The cost is root, device-specific GPU work, and a remaining Steam bring-up milestone.
