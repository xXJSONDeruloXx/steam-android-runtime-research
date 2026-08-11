# Nova rootless R6e — closure validator retry predeclaration — 2026-08-11

Run ID: `nova-rootless-r6e-20260811T060037Z`
Sub-run: `R6e-closure-validator`
Status: predeclared; the prior R6d tree will be cleaned before launch.

## Controlled change

R6d reached the complete 103-package pacman transaction, but the guest shell
did not export the normal guest PATH and the host validator treated valid
guest-absolute Debian library symlinks as missing. R6e changes only the
closure helper: it exports `PATH=/usr/bin:/bin:/usr/sbin:/sbin` inside the
guest install script and uses a symlink-aware host check after the guest-side
closure marker has validated the actual GTK2/audio targets.

The Holo archive, PRoot, extraction/owner normalization, complete 103-package
manifest, Debian assets, Steam client, display, network, audio, input, and
auth variables remain unchanged. The rooted Holo tree remains a read-only
bootstrap input and is never modified or treated as rootless evidence.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `965dda2` (`fix: run rootless package hooks in guest path`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r6e-20260811T060037Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r6e-20260811T060037Z/
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

No Steam authentication data is exported, copied, or staged.

## Run sequence and acceptance

1. Remove only the R6d app-private and remote trees, verify no matching
   PRoot/pacman/bsdtar process remains, confirm rollback paths/free space, and
   install the pinned APK.
2. Stage the archive, PRoot closure/symlinks, all 103 Holo package artifacts,
   both Debian GTK2 assets, combined manifest, and helper scripts. Verify
   hashes as the app UID and do not pre-create either atomic destination.
3. Repeat extraction and require the app-readable/executable candidate gate.
4. Run package closure into `guest-rootfs-closure/` with an empty app-owned
   Steam-client directory. Require pacman completion, no guest-PATH hook
   failures for ordinary tools, the guest-side closure marker, symlink-aware
   GTK2/audio paths, and no partial destination.
5. Stop at the first failed gate and document it. Do not start Steam or
   Termux:X11 in this sub-run.

## Cleanup

Capture both helper logs, remove only the named R6e remote and app-private
trees after documenting the result, verify no PRoot/pacman/bsdtar process or
staging directory remains, and confirm rooted rollback paths are unchanged.

