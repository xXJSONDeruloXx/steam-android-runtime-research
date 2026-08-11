# Nova rootless R7c — PRoot `libtalloc` soname retry predeclaration — 2026-08-11

Run ID: `nova-rootless-r7c-libtalloc-soname-20260811T061708Z`
Sub-run: `R7c-libtalloc-soname`
Status: predeclared; the failed R7b tree was removed before launch.

## Controlled change

R7b proved that absolute app-private PRoot paths reach the executable but
stopped because the staged library directory contained only
`libtalloc.so.2.4.3`. R7c adds the two app-owned compatibility links used by
the known-good R6 staging:

```text
libtalloc.so.2 -> libtalloc.so.2.4.3
libtalloc.so   -> libtalloc.so.2.4.3
```

No helper, archive, package, seed, guest closure, supervisor, display,
network, audio, input, or rooted-runtime variable changes. The links are
created only in the R7c app-private PRoot library directory. No Steam home or
authentication data is copied or exported.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `0c1517f` (`docs: record rootless R7b libtalloc boundary`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r7c-libtalloc-soname-20260811T061708Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7c-libtalloc-soname-20260811T061708Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  guest-rootfs-closure/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Run sequence and acceptance

1. Verify the new exact scope is absent, no matching process remains, app
   free space and UID are sufficient, and rooted rollback paths are present.
2. Restage the same pinned public artifacts and verify archive/hash,
   103-package count, seed layout, and no authentication data.
3. Create and verify only the two `libtalloc` soname links in the app-owned
   `proot/lib` directory. Invoke the unchanged extractor using absolute paths.
   Require the archive hash/size gate, Holo `bsdtar` completion, app-readable
   candidate, and no partial destination.
4. If extraction passes, run the unchanged 103-package plus Debian guest
   closure with the public seed bound at `/opt/nova-steam`. Require the guest
   marker and a clean `steamui.so` `ldd` result.
5. If closure passes, run supervisor `preflight` and only
   `/opt/nova-steam/steamrtarm64/steam --version` with fresh state/log files.
   Do not start Termux:X11 in this run.
6. Stop at the first failed gate, document, commit, and push before any
   further input changes.

## Cleanup

After recording the result, remove only the R7c app-private and remote trees;
verify no matching PRoot/pacman/bsdtar/Steam/Termux:X11 process or staging
directory remains, and confirm rooted rollback paths are unchanged.

## Follow-up

An extraction pass advances to the seed-bound closure. A closure and
`steam --version` pass advances to a fresh Termux:X11 SteamUI run. The
SteamRT3C archive and Runtime 4/Proton 11 remain later independently
predeclared boundaries; Gamescope/AHardwareBuffer remains optional.
