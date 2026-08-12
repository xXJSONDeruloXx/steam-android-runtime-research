# AYN Thor rootless R38 libtalloc soname retry — predeclaration — 2026-08-12

Run identity: `thor-rootless-r38-stable-payload-replay-retry2-20260812T004450Z`;
sub-run: `R38-stable-payload-replay-retry2-libtalloc-soname`.

Status: predeclared as a fresh retry after the invalid bsdtar/loader result in
doc 510. The nearest blocker is exact and known: the app-owned PRoot library
directory has `libtalloc.so.2.4.3` but the Android linker requires the soname
`libtalloc.so.2`.

## One corrected infrastructure input

After staging the unchanged pinned library bytes, create exactly these two
links inside the fresh app-owned PRoot library directory:

```text
libtalloc.so.2 -> libtalloc.so.2.4.3
libtalloc.so   -> libtalloc.so.2.4.3
```

Verify both are symlinks, resolve to the pinned file, and are visible to the
real app UID. Do not modify the `libtalloc.so.2.4.3` bytes or add any other
library, loader, environment, archive, client, or Steam change. This is the
same narrow correction established by the Nova R7c soname experiment.

## Fixed experiment

Keep all doc 509/R38 values fixed:

```text
stable_manifest_sha256=a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91
stable_payload_sha256=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
stable_decoded_zip_sha256=aed451902b2239cbf8a16e1a2004e016cea803d562849a4969b01a93c9cb4821
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
bsdtar_manifest_sha256=8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
serial=d234a848
app_uid=10138
display=127.0.0.1:77
```

Use fresh app-owned R38 state and the same exact R38 device scope after doc
510 proves it absent. Keep app-UID PRoot `-0`, direct TCP Termux:X11,
inherited Android network, short temporary paths, fresh resolver, and the
exact stable client tree. Keep both Vulkan selectors, Mesa overrides,
`LD_PRELOAD`, `/dev/shm`, D-Bus, machine-id, Runtime 4, Proton, FEX/DXVK,
Gamescope, AHardwareBuffer, controller/audio helpers, and SteamUI patches
unset.

## Acceptance order

1. Verify both soname links and the pinned bytes under UID 10138.
2. Require `nova_rootless_rootfs_archive=pass` using the pinned app-owned
   bsdtar bootstrap.
3. Require the 161-package plus two-asset guest closure and fresh rootless
   preflight.
4. Require fresh X11/listener/handshake evidence and all four stable native
   hashes.
5. Only then launch the unchanged R38 Steam command and classify the first
   native boundary: `vgui2_s`, native SteamUI/webhelper, Vulkan, or later
   prerequisites. Do not combine another fix into this retry.

Any wrong hash, stale scope, UID/device mismatch, unexpected variable, or
pre-Steam infrastructure failure is `invalid`; stop, capture, clean, document,
and push before another correction. A black X11 canvas is not a Steam frame.

## Cleanup and authentication boundary

Terminate only the exact retry processes, restore Termux properties byte-for-
byte if temporarily changed, remove only the exact R38 scopes, verify no
Steam/PRoot/bsdtar/pacman/webhelper/X11 process or 6077 listener remains, and
verify both rooted rollback paths. Never read, copy, back up, commit, or export
Steam authentication state.
