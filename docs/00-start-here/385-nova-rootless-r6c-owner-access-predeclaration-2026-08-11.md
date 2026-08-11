# Nova rootless R6c — owner-access normalization predeclaration — 2026-08-11

Run ID: `nova-rootless-r6c-20260811T054707Z`
Sub-run: `R6c-owner-access-normalization`
Status: predeclared; the R6b tree will be cleaned before launch.

## Controlled change

R6b showed that Holo `bsdtar` returns success while preserving archive modes
that make some files unreadable to the app UID. R6c changes only the
post-extraction staging step: the helper runs `chmod -R u+rwX` on the
app-owned staging tree before validating and atomically activating it. This
adds owner read/write access and restores owner execute access when the
archive has an execute bit, without requiring root ownership restoration.

The Holo ARM64 tree remains a read-only PRoot bootstrap input. R6c does not
copy or modify it, use `su`, `chroot`, or `mount`, and no rooted path is used
as rootless runtime evidence.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `61105c9` (`fix: normalize rootless guest owner access`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `f499d43a66492262e4002b33f8185f434e56af334024e48ee97b9cf3aa1fc9d1`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r6c-20260811T054707Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r6c-20260811T054707Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  guest-rootfs-closure/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

The rooted rollback paths remain outside scope and must not be changed:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication data is exported, copied, or staged.

## Run sequence and acceptance

1. Clean only the R6b app-private and remote trees, verify no matching
   PRoot/bsdtar process remains, and confirm the rooted rollback paths and
   free-space gate.
2. Install and hash the pinned APK. Stage and app-own the archive, PRoot
   closure, symlinks, package closure, and manifests without pre-creating
   either atomic rootfs destination.
3. Run app-UID Holo `bsdtar` extraction. Require no PRoot warning, the
   archive marker, required glibc/pacman paths, app ownership, and successful
   `test -r` and `test -x` for the previously failing helper.
4. If the readability gate passes, run the existing package-closure helper
   into `guest-rootfs-closure/` using an empty app-owned Steam-client
   directory. Require all package hashes, closure marker, GTK2/audio library
   paths, and no partial destination.
5. Stop at the first failed gate, document it, and do not start Steam or
   Termux:X11 in this sub-run.

## Cleanup

Capture both helper logs, remove only the named R6c remote and app-private
trees after documenting the result, verify no PRoot/bsdtar process or staging
directory remains, and confirm the rooted rollback paths are unchanged.

