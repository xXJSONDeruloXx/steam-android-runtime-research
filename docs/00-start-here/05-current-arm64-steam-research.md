# Current ARM64 Steam and SteamOS-session research

Snapshot date: 2026-08-07. This is a dated observation, because the Steam client channel and both
community distributions are changing quickly.

## Executive finding

The native ARM64 Steam client is now directly reachable from Valve distribution endpoints. The missing
piece is no longer “can an ARM64 Steam binary be obtained?” It is the surrounding Linux session and
Android presentation boundary.

Two independent ARM handheld distributions now describe the complete path:

```text
native ARM64 Steam
  -> gamescope / Xwayland
    -> Steam Gamepad UI (Big Picture)
      -> Proton ARM64 and/or FEX for x86 games
```

Armada and PockNix run this as a complete Linux image on supported Qualcomm handhelds. They do not show
that an ordinary Android app can reproduce the same path without root, a bootloader change, or kernel/GPU
ownership. That distinction is the central update to the earlier research.

## Valve distribution endpoints

The current checks returned:

| Artifact | Endpoint | Observation |
|---|---|---|
| ARM64 client manifest | [`steam_client_steamdeck_publicbeta_linuxarm64`](https://client-update.steamstatic.com/steam_client_steamdeck_publicbeta_linuxarm64) | HTTP 200; 12,578-byte binary manifest; resolved `bins_linuxarm64_linuxarm64.zip.0f238017c65e844f71581d1fae8fb42f410e1032` on this date |
| SteamRT3C ARM64 pointer | [`latest-public-beta.txt`](https://repo.steampowered.com/steamrt3c/images/latest-public-beta.txt) | HTTP 200; resolved snapshot `3c.0.20260714.251839` |
| Holo package channel | [`holo-core-aarch64-preview`](https://holo-packages.steamos.cloud/holo-core-aarch64-preview/) | HTTP 200; current index exposed `mash-20251118.3`, including a 367.1 MiB `system.rootfs.zst` and `core`/`extra` ARM64 package trees |

The client manifest is not a normal Arch package. Armada and PockNix both parse the Valve manifest,
download the ARM64 seed, and then run the client once under a virtual X display so Steam can lay out the
complete install and write its `.installed` manifest. This is why a Linux image can ship a working ARM64
Steam session without pretending the client is a pacman/RPM package.

The `steamdeck_publicbeta` channel matters in the community launchers: PockNix records that the plain
`publicbeta` channel did not contain the Gamepad UI payload it needed, while `steamdeck_publicbeta` did.
That is repository evidence rather than a Valve compatibility guarantee, so the channel must remain a
runtime/build-time probe rather than a permanently hard-coded promise.

## Holo: useful ARM64 base, not a complete Steam image

Source: [holo-core-aarch64-preview](https://gitlab.steamos.cloud/holo/holo-core-aarch64-preview/), inspected
at commit `67f0d559c82cdc5c94317bad53ae45409720ef59`.

The Holo repository identifies itself as a read-only Arch Linux `aarch64` preview package source and links
to the live package channel. The checked-out tree contains 163 `core-aarch64` and 2,094 `extra-aarch64`
PKGBUILD trees, plus `core-any`/`extra-any` sources. The live channel exposed the following relevant ARM64
artifacts on the snapshot date:

- `gamescope-3.16.17-1-aarch64.pkg.tar.zst`;
- Mesa 25.2.7, including `vulkan-freedreno`;
- Wayland 1.24.0, Xwayland, libdrm, PipeWire, Vulkan loader/tools;
- glibc 2.42 and Linux 6.17.8 packages;
- an ARM64 rootfs/container baseline.

Holo's gamescope packaging is the ordinary Valve/Arch SteamOS compositor build, marked for both
`x86_64` and `aarch64`, with DRM, Wayland, Xwayland, PipeWire, Vulkan, and `seatd` dependencies. It is a
strong dependency/ABI source for an ARM64 Linux userspace. It is not an Android graphics bridge, a device
kernel/configuration, or a native Steam client package. The checked-out Holo tree has no Steam, Proton, or
FEX package directory; the native client is delivered by Valve's client channel and game compatibility is
assembled separately by projects such as Armada/PockNix.

## Armada: complete SteamOS-like ARM session

Source: [armada-os/armada](https://github.com/armada-os/armada), inspected at commit
`adbd224c9dbde07cb1e77c0642fcb8dc345e2cfa`.

Armada is a Fedora bootc image with ROCKNIX device support. Its README lists ARM64 Steam, FEX, ARM
CachyOS Proton, KDE desktop mode, input/power controls, and install alongside Android. The README also
reports that after boot the Steam first-run flow eventually reaches the login screen, with a known black
delay on the current SD-card path. That makes it the strongest current end-to-end session evidence, while
still being a project claim to reproduce on the exact target device rather than an independent test run.

The reusable parts are concrete:

- [`build_files/generate-steam-bootstrap.sh`](https://github.com/armada-os/armada/blob/adbd224c9dbde07cb1e77c0642fcb8dc345e2cfa/build_files/generate-steam-bootstrap.sh) resolves the SteamRT3C ARM64 snapshot, downloads the
  `steamdeck_publicbeta` ARM64 client manifest/payload, creates the `.steam` symlink layout, and runs the
  ARM client under Xvfb to produce a complete client tree.
- [`system_files/etc/gamescope-session-plus/sessions.d/steam`](https://github.com/armada-os/armada/blob/adbd224c9dbde07cb1e77c0642fcb8dc345e2cfa/system_files/etc/gamescope-session-plus/sessions.d/steam) starts the Steam Deck-style client with
  `-gamepadui -steamos3 -steampal -steamdeck` and exports panel/HDR/compatibility-tool settings.
- [`system_files/usr/libexec/armada/launch-steam`](https://github.com/armada-os/armada/blob/adbd224c9dbde07cb1e77c0642fcb8dc345e2cfa/system_files/usr/libexec/armada/launch-steam) puts `steamrtarm64` and the ARM64 shim directory first
  on `LD_LIBRARY_PATH`, registers the ARM Proton tool when present, and executes the native ARM client.
- [`armada-game-launch`](https://github.com/armada-os/armada/blob/adbd224c9dbde07cb1e77c0642fcb8dc345e2cfa/system_files/usr/libexec/armada/armada-game-launch) applies per-game FEX profiles and Proton environment fixes. FEX is for x86 game
  content; it is not needed to execute the native ARM64 Steam UI.
- The [`Containerfile`](https://github.com/armada-os/armada/blob/adbd224c9dbde07cb1e77c0642fcb8dc345e2cfa/Containerfile) composes FEX, patched Mesa, gamescope, gamescope-session, inputplumber, kernel,
  firmware, and device packages into a bootable image.

What does not transfer directly to an Android app:

- booting uses a ROCKNIX-derived ABL and a Linux SD/internal image;
- gamescope uses a DRM/KMS seat and device-specific kernel/firmware/GPU support;
- input, audio, power, and realtime scheduling are system services;
- installing or recovering the image can require Android root, repartitioning, or fastboot.

Armada therefore proves “the target Linux session is viable,” not “the session is rootless inside Android.”

## PockNix: closest portable session recipe

Source: [shuuri-labs/pocknix-os](https://github.com/shuuri-labs/pocknix-os), inspected at commit
`fdfda2a7c4434ea2a24f3f40a00dc1b460e7aaf7`.

PockNix is explicit about the desired user experience: native ARM64 Steam, boot straight into
gamescope-backed SteamOS mode, and a second Plasma Mobile session. Its README describes the device as
power-on → Big Picture → choose a game → play. This is the closest public repository to the intended
product session semantics.

The most reusable code is [`packages/pocknix-steam/pocknix-steam`](https://github.com/shuuri-labs/pocknix-os/blob/fdfda2a7c4434ea2a24f3f40a00dc1b460e7aaf7/packages/pocknix-steam/pocknix-steam):

- it requires the pre-seeded `steamrtarm64/steam` native client;
- pins `steamdeck_publicbeta` before every launch;
- runs `pocknix-proton-prep` before Steam scans compatibility tools;
- loads device-specific panel geometry and physical millimeters for correct Gamepad UI sizing;
- starts `gamescope --backend drm --xwayland-count 2 --mangoapp -e` and then the same
  `-gamepadui -steamos3 -steampal -steamdeck` client flags;
- logs the session and supervises return to a shell after repeated fast failures.

Its installer and build path are also important evidence:

- [`pocknix-steam-install`](https://github.com/shuuri-labs/pocknix-os/blob/fdfda2a7c4434ea2a24f3f40a00dc1b460e7aaf7/packages/pocknix-steam/pocknix-steam-install) downloads the same Valve SteamRT3C ARM64 runtime and `steamdeck_publicbeta`
  ARM64 client, then bootstraps it under Xvfb. The client is baked into the image; the on-device launcher
  intentionally has no network-install fallback.
- The build script validates `steamui.so` and the `.installed` manifest, then includes the roughly 1.3 GB
  client tree in the image before the partition is sized.
- A non-root `deck` user owns the Steam session and is used because PipeWire and Proton prefer a real
  user session. Root services still provide `seatd`, input plumbing, realtime gamescope scheduling,
  power, and FEX/binfmt handling.
- The custom gamescope package carries touch input, fake physical output size, gamepad cursor, and
  compositor-rotation patches for Qualcomm panels. This is exactly the kind of device-specific work a
  generic Android package cannot assume away.

PockNix also documents the remaining boot boundary: SM8550 devices need a ROCKNIX ABL flashed from
rooted Android, while SM8250 devices can use the stock ABL; SD boot is the default and internal install
resizes Android storage. Its source build needs an aarch64 Linux host with root because it chroots and
builds a kernel/image.

## What moved forward, and what did not

### Moved forward

- Native ARM64 Steam is available through a live Valve client manifest and ARM64 SteamRT channel.
- The ARM64 Linux dependency stack is available as a Holo preview package/rootfs channel.
- Native Steam + gamescope + Gamepad UI is no longer just a theoretical composition: Armada and PockNix
  both implement it for real Qualcomm handheld Linux images.
- The client bootstrap problem is understood well enough to be made reproducible: fetch the ARM64 seed,
  create the `.steam` links, run one updater pass under Xvfb, and preserve the complete ARM tree.

### Still does not work as a finished Android app

- Neither Armada nor PockNix runs inside an ordinary Android application sandbox.
- Their gamescope path is DRM/KMS-based; an Android app normally owns a `Surface`/`ANativeWindow`, not
  DRM master, a Linux seat, or a KMS connector.
- Rootless Android process/filesystem isolation, user namespaces, bind mounts, realtime scheduling,
  GPU buffer import, and controller injection remain separate engineering problems.
- FEX/Proton is still needed for x86 Windows games. Native ARM64 Steam only removes translation from the
  Steam client/UI path; it does not make every game native ARM64.
- Holo is a technology preview and does not provide a device boot image, Snapdragon kernel enablement,
  or the Steam client itself.

## Consequence for this project

The product should be designed as an Android control plane around a Linux Steam session, not as a second
Steam UI. The first app milestone can require root and should use the ARM64 client/session recipe proven
by these projects, with the AHardwareBuffer/Surface presentation path from `steam-arm-findings`. A later
rootless milestone can replace only the privileged process/rootfs/display pieces after each contract has a
working substitute.

## Reproducibility notes

The three repositories were shallow-cloned outside this evidence repository under
`/Users/danhimebauch/Developer/.external-research/` and are not copied into the private archive. The
archive records source URLs and commits so the evidence can be refreshed without committing Valve runtime
binaries or large OS images.
