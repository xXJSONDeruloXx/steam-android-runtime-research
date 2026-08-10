# Nova Geometry Wars bounded-log control — ENOSPC preflight and storage-reclaim result — 2026-08-10

## Result

This is a **harness/storage preflight failure**, not a Geometry Wars or Vulkan
result. The visible Nova Lab APK launched, but tapping `Start Steam` failed
inside the launcher with:

```text
Cannot prepare launcher: write failed: ENOSPC (No space left on device)
```

No fresh Nova, Gamescope, Steam, Proton, Wine, X11, or game session started
under this run identity. There is therefore no first-frame or Vulkan/WSI
classification to make from this control.

## Run identity and fixed scope

- Run ID:
  `nova-game-geometry-wars-one-click-first-frame-logbound-20260810T164455Z`
- Predeclaration commit:
  `05ff1f524b1aa68ebda40b7e0b7f91e293d26aa5`
- Device: Retroid Pocket Nova, Android 13, `kalama`, adb serial `675a2365`
- APK SHA-256:
  `0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97`
- Parent profile and game delta: unchanged from [330](330-nova-geometry-wars-one-click-first-frame-logbound-predeclaration-2026-08-10.md)

The lifecycle contract in [34](34-nova-runtime-harness-lifecycle.md) was read
in full before the device preflight. Exact launcher cleanup passed before the
APK was started. The screenshot proved the visible `Start Steam` button was
present, and one tap was issued; the launcher then failed while preparing its
run state. This is not a failed input or readiness observation.

## Why the earlier deletion did not reclaim space

The exact prior run tree was absent:

```text
/data/local/tmp/nova-holo-rootfs/tmp/nova-game-geometry-wars-one-click-first-frame-20260810T161132Z
```

The pathname of its Proton log was also absent, which initially made the
earlier `~31 GB removed` statement look complete. A descriptor audit found the
missing detail: five orphaned UID-501 Wine processes still had the unlinked
file open as fd 2:

```text
/proc/2833/fd/2 -> .../proton-log/steam-8400.log (deleted)  services.exe
/proc/2851/fd/2 -> .../proton-log/steam-8400.log (deleted)  plugplay.exe
/proc/2865/fd/2 -> .../proton-log/steam-8400.log (deleted)  svchost.exe
/proc/2956/fd/2 -> .../proton-log/steam-8400.log (deleted)  explorer.exe
/proc/2979/fd/2 -> .../proton-log/steam-8400.log (deleted)  rpcss.exe
```

All five had `PPID 1` and were stale remnants of the earlier Geometry Wars
run. The exact PIDs were terminated. The device immediately changed from:

```text
/dev/block/dm-14 101G 101G 0 100%
13511677 total inodes, 0 free
```

to:

```text
/dev/block/dm-14 101G 30G 71G 30%
13511677 total inodes, 13309352 free
```

After `sync`, the device remained at 71 GB available and more than 13.3
million free inodes. The exact stale dbus/at-spi processes (PIDs 643, 1116,
and 1122) were then terminated, and the exact launcher cleanup helper passed.

Two unrelated historical `steam-8400.log` files remain, each 66 KB:

```text
/data/local/tmp/nova-holo-rootfs/tmp/nova-android-wsi-layer-x11-20260810T114402Z/proton-log3/steam-8400.log
/data/local/tmp/nova-holo-rootfs/tmp/nova-proton-dxvk-nativeoverride-20260810T082211Z/steam-8400.log
```

They are not the deleted 31 GB log and are not open by a current Nova session.
The retained Proton 11 ARM64 tool, Geometry Wars installation, Steam runtimes,
and GameNative data were not removed.

## Classification and next control

Classification: **invalid preflight — storage exhaustion before launcher
startup**. This run must not be compared with the prior game result and
provides no evidence for or against Vulkan, DXVK, Win32-surface WSI, Gamescope,
or Android presentation.

The next attempt must use a new run identity and recheck both byte and inode
availability after exact cleanup. It may then repeat the predeclared
`WINEDEBUG=+loaddll` control with no parent/rendering changes.
