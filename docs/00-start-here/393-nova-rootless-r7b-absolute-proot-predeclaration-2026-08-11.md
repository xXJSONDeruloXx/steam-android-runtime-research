# Nova rootless R7b — absolute PRoot path retry predeclaration — 2026-08-11

Run ID: `nova-rootless-r7b-absolute-proot-20260811T061455Z`
Sub-run: `R7b-absolute-proot-path`
Status: predeclared; the failed R7 staging tree was removed before launch.

## Controlled change

R7 verified the public seed and archive but stopped before extraction because
the invocation supplied relative PRoot and loader paths. Android's linker did
not resolve the relative PRoot library directory and reported
`libtalloc.so.2` missing. R7b changes only those invocation values to absolute
app-private paths. The archive extractor, PRoot binary/loader/libs, Holo
archive, 103-package closure, Debian assets, public Steam seed, guest closure,
supervisor, and all product/runtime variables remain unchanged.

The rooted Holo tree is a read-only bootstrap input and is never modified.
No Steam home, login token, cookie, sentry file, or other authentication data
will be copied or exported.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `1b2d51d` (`docs: record rootless R7 relative PRoot path boundary`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- PRoot package source: `android/nova-lab/build/rootless-termux/`, with the
  binary, static loader, and `libtalloc.so.2.4.3` staged app-readably.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r7b-absolute-proot-20260811T061455Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7b-absolute-proot-20260811T061455Z/
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

1. Verify the new exact scope is absent, app UID/free space are sufficient,
   no matching process remains, and rooted rollback paths are present.
2. Restage the same pinned public artifacts and verify the app-owned archive,
   package count, seed binary, and no authentication data.
3. Invoke the unchanged extractor with absolute values for every app-private
   PRoot path, including `NOVA_ROOTLESS_PROOT_LIB_DIR`. Require the archive
   hash/size gate, app-readable candidate, required loader paths, and no
   partial destination.
4. If extraction passes, run the unchanged complete guest closure with
   `/opt/nova-steam` bound to the public seed. Require 103 Holo packages, both
   Debian assets, guest GTK2/audio paths, and a clean `steamui.so` `ldd` check.
5. If closure passes, run supervisor `preflight` and only
   `/opt/nova-steam/steamrtarm64/steam --version` with a fresh state/log
   directory. Do not start Termux:X11 or claim UI/network/audio/controller/
   login/game success from this retry.
6. Stop at the first failed gate, capture the exact output and classify it,
   then document, commit, and push before any helper or input changes.

## Cleanup

After the result is recorded, pull only bounded helper output, remove the
named R7b app-private and remote trees, verify no matching PRoot/pacman/bsdtar/
Steam/Termux:X11 process or staging directory remains, and confirm rooted
rollback paths are unchanged.

## Follow-up

An extraction pass advances to the seed-bound closure. A closure and
`steam --version` pass advances to a separately predeclared Termux:X11
SteamUI run. The official SteamRT3C archive and Runtime 4/Proton 11 remain
later boundaries; Gamescope/AHardwareBuffer remains optional and outside this
rootless critical path.
