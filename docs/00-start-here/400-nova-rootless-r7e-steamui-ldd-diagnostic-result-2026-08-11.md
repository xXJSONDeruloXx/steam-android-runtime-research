# Nova rootless R7e — `steamui.so` dependency diagnostic result — 2026-08-11

Run ID: `nova-rootless-r7e-steamui-ldd-diagnostic-20260811T062455Z`
Sub-run: `R7e-steamui-ldd-diagnostic`
Status: diagnostic passed; exact missing public-SteamUI dependencies captured.

## Result

The unchanged archive extractor passed and the unchanged 103-package plus
Debian closure passed when its client bind was an empty app-owned directory:

```text
nova_rootless_rootfs_archive=pass rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7e-steamui-ldd-diagnostic-20260811T062455Z/guest-rootfs
nova_rootless_guest_rootfs=pass rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7e-steamui-ldd-diagnostic-20260811T062455Z/guest-rootfs-closure
```

With that activated candidate, a fresh app-UID PRoot command bound the real
public ARM64 seed at `/opt/nova-steam` and ran only:

```text
/usr/bin/ldd /opt/nova-steam/steamrtarm64/steamui.so
```

The complete diagnostic returned `ldd_exit=0` but reported these unresolved
objects:

```text
libSDL3.so.0
libavcodec.so.62
libavformat.so.62
libswresample.so.6
libavutil.so.60
libswscale.so.9
libavfilter.so.11
```

All other direct and transitive entries shown by `ldd` resolved through the
Holo guest, the Debian GTK2 overlay, or the public seed. The pinned Holo
artifact directory already contains exact providers for every missing object:

```text
sdl3-3.2.26-1-aarch64.pkg.tar.zst
ffmpeg-2:8.0-3-aarch64.pkg.tar.zst
```

The current 103-entry rootless Holo manifest does not include either package.
This gives the next closure change an exact, source-available scope rather
than a speculative library search.

No Steam executable, `steamwebhelper`, supervisor, Termux:X11 server, display,
network, audio, controller, login, or game path was started. No rooted runtime
was modified, and no Steam authentication data was exported or copied.

## Classification

This closes the R7 seed-to-Holo dependency diagnostic. The failure is a
narrowly missing Holo package closure, not a WSI/display boundary, and not a
Proton/game result. The next run may add only the two pinned Holo packages
above, update the manifest/hash/count, and repeat the truthful seed-bound
closure. Do not patch SteamUI or add unrelated compatibility libraries.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `b65287c` (`docs: predeclare rootless R7e SteamUI ldd diagnostic`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Existing closure: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Proposed additions: `sdl3` and `ffmpeg` from the pinned Holo artifact set.

## Cleanup and next boundary

The exact R7e app-private and remote trees must be removed after this result
is pushed. The next predeclared run must use a new scope, add only the two
provider packages, record the new manifest count/hash, and require the real
seed-bound closure to pass before attempting `steam --version`.

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```
