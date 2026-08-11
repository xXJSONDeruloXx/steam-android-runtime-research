# Nova rootless R6d — complete Holo closure predeclaration — 2026-08-11

Run ID: `nova-rootless-r6d-20260811T055439Z`
Sub-run: `R6d-complete-holo-closure`
Status: predeclared; the prior R6c tree will be cleaned before launch.

## Controlled change

R6c proved extraction and app-readability, then showed that the 44-package
rootless manifest was only an incremental SteamUI/audio overlay. R6d changes
only the package input set: it uses the combined 103-entry manifest containing
the pinned 59-package direct Termux:X11 Holo closure plus the 44-package
SteamUI/audio overlay. Pacman dependency checks remain enabled; no `--nodeps`
fallback is allowed.

The Holo rootfs archive, PRoot, extraction mode, owner-access normalization,
Debian GTK2 assets, Steam client, display, network, audio, input, and auth
variables remain unchanged. The rooted Holo tree is a read-only bootstrap
input only and is never modified or used as rootless evidence.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `850cd3c` (`fix: make rootless Holo closure complete`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `ba5133f7f053fa6607fffb1cc7d9bc8c126786955e8be9888e5eb70337eb04a1`.
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
/data/local/tmp/nova-rootless-r6d-20260811T055439Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r6d-20260811T055439Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  guest-rootfs-closure/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

The rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication data is exported, copied, or staged.

## Run sequence and acceptance

1. Remove only the R6c app-private and remote trees, verify no matching
   PRoot/bsdtar process remains, confirm rollback paths/free space, and install
   the pinned APK.
2. Stage all 103 package artifacts, the combined manifest, archive, PRoot
   closure/symlinks, and helper scripts. Verify all hashes as the app UID and
   do not pre-create either atomic rootfs destination.
3. Repeat app-UID archive extraction and require the no-warning,
   owner-readable/executable candidate gate.
4. Run the closure helper into `guest-rootfs-closure/` with an empty
   app-owned Steam-client directory. Require pacman to complete its dependency
   transaction, the closure marker, GTK2/audio library paths, and no partial
   destination.
5. Stop at the first failed gate and document it. Do not start Steam or
   Termux:X11 in this sub-run.

## Cleanup

Capture both helper logs, remove only the named R6d remote and app-private
trees after documenting the result, verify no PRoot/bsdtar process or staging
directory remains, and confirm rooted rollback paths are unchanged.

