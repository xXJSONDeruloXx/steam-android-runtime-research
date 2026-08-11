# Nova rootless R12c — complete bootstrap closure predeclaration — 2026-08-11

Run ID: `nova-rootless-r12c-libc-bootstrap-20260811T085929Z`
Sub-run: `R12c-rootless-apk-materialized-complete-bsdtar-closure`
Status: predeclared after R12b identified the single omitted `libc.so.6` APK
asset and the fix was committed and pushed.

## Controlled change

R12c adds only `nova-bsdtar-bootstrap/lib/libc.so.6` to the APK's required
asset copy list. The Holo archive, PRoot/loader/lib inputs, app-owned
bootstrap layout, extractor command, display, and all other variables remain
unchanged. No Steam command or network behavior is part of this run.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code state: commit `71718b7` (`fix: include libc in rootless bootstrap
  assets`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `b5bc9a9f4a8b2fd4e4ce1bc4c16f8f07bc696660ae057b30ac30404bd5b009d6`.
- Bootstrap manifest: 17 files, SHA-256
  `704b488c54d41c02744f5e81e44fcf90b7142b6a7ffdab007014e24487df09fa`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r12c-libc-bootstrap-20260811T085929Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12c/
/data/data/com.termux/files/home/.nova-rootless/
```

Retain the APK's static `files/launcher` asset cache for inspection. Preserve
and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R12c scopes/process/listener,
   free space, and rollback state.
2. Install/hash-verify the pinned APK. Start rootless X11 through the APK so
   `prepareLauncherAssets()` copies all 17 bootstrap files and rootless
   helpers. Verify `libc.so.6` is present and hash it against the generated
   manifest; require the app-UID X11 transport pass.
3. Push/copy only the pinned Holo archive and PRoot/loader/lib closure into
   fresh R12c state. Use the APK-materialized helper and app-owned bootstrap:

   ```text
   NOVA_ROOTLESS_ROOTFS_ARCHIVE=files/r12c/system.rootfs.zst
   NOVA_ROOTLESS_GUEST_ROOTFS=files/r12c/guest-rootfs
   NOVA_ROOTLESS_BOOTSTRAP_ROOTFS=files/launcher/nova-bsdtar-bootstrap
   NOVA_ROOTLESS_ZSTD=files/r12c/proot/nova-zstd
   NOVA_ROOTLESS_PROOT_BIN=files/r12c/proot/proot
   NOVA_ROOTLESS_PROOT_LOADER=files/r12c/proot/loader
   NOVA_ROOTLESS_PROOT_LIB_DIR=files/r12c/proot/lib
   NOVA_ROOTLESS_STATE=files/r12c/state
   ```

   Acceptance is `nova_rootless_rootfs_archive=pass`, required glibc/pacman
   paths, archive marker, and `rooted_runtime_modified=0`. The rooted rollback
   path must not appear as a bootstrap input.
4. Stop X11 through the APK, remove only the R12c runtime/Termux scopes, and
   verify no process/listener residue, rollback preservation, and free space.
   Do not launch Steam.

## Interpretation

A pass closes the app-owned clean-device archive extraction boundary. A failure
must remain classified at bootstrap dependency or archive extraction before
any Steam updater or runtime variable changes.
