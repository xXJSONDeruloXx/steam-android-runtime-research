# Nova rootless R12b — helper asset retry predeclaration — 2026-08-11

Run ID: `nova-rootless-r12b-helper-assets-20260811T085212Z`
Sub-run: `R12b-rootless-apk-materialized-bsdtar-and-extractor`
Status: predeclared after R12's packaging failure was documented and pushed.

## Controlled change

R12 proved that the new APK materialized the 17-file app-owned `bsdtar`
bootstrap, but failed before extraction because
`nova-rootless-extract-rootfs.sh` was not in `LauncherActivity`'s copy list.
The APK now materializes the complete rootless helper set, including
`nova-zstd`, the extractor, supervisor, profile, package manifests, and
Termux/X11 helpers.

R12b changes only that APK asset-materialization list. It keeps the Holo
archive, PRoot, loader, bootstrap closure, display, and command unchanged. It
does not launch Steam or exercise networking, authentication, SteamUI, Proton,
Gamescope/AHardwareBuffer, controller, or audio.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code state: commit `83d07dd` (`fix: materialize rootless helper assets`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `c90a8a2566f80076956d8c95ddbe9ae19cdf83446fb782ee072d15f0304d16a2`.
- Bootstrap manifest: 17 files, SHA-256
  `704b488c54d41c02744f5e81e44fcf90b7142b6a7ffdab007014e24487df09fa`.
- `bsdtar` SHA-256:
  `0cf2ec3c3ec5c23c59eb7b755fb6ca2e0393aa82f75aba6959cffeb32086d7d6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r12b-helper-assets-20260811T085212Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12b/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK materialization under
`/data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/` remains
outside the run scope and is retained for hash inspection. The rooted rollback
paths must remain present and untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the Nova lifecycle contract. Verify the R12b scopes, exact process
   tree, `:77` listener, free space, and rollback paths.
2. Install and hash-verify the pinned APK. Launch rootless X11 through the APK
   so `prepareLauncherAssets()` materializes both the bootstrap and helper
   files. Verify these app-owned paths and hashes as UID `10128`:

   ```text
   files/launcher/nova-bsdtar-bootstrap/manifest.tsv
   files/launcher/nova-bsdtar-bootstrap/usr/bin/bsdtar
   files/launcher/nova-rootless-extract-rootfs.sh
   files/launcher/nova-zstd
   ```

   Require the app-UID X11 loopback transport pass.
3. Push only the pinned archive and PRoot/loader/lib closure into fresh R12b
   staging, copy them into `files/r12b`, and verify their hashes. Do not use
   the rooted rollback path as `NOVA_ROOTLESS_BOOTSTRAP_ROOTFS`.
4. Run the APK-materialized helper with:

   ```text
   NOVA_ROOTLESS_ROOTFS_ARCHIVE=files/r12b/system.rootfs.zst
   NOVA_ROOTLESS_GUEST_ROOTFS=files/r12b/guest-rootfs
   NOVA_ROOTLESS_BOOTSTRAP_ROOTFS=files/launcher/nova-bsdtar-bootstrap
   NOVA_ROOTLESS_ZSTD=files/r12b/proot/nova-zstd
   NOVA_ROOTLESS_PROOT_BIN=files/r12b/proot/proot
   NOVA_ROOTLESS_PROOT_LOADER=files/r12b/proot/loader
   NOVA_ROOTLESS_PROOT_LIB_DIR=files/r12b/proot/lib
   NOVA_ROOTLESS_STATE=files/r12b/state
   ```

   Acceptance is `nova_rootless_rootfs_archive=pass`, the archive marker,
   required glibc/pacman paths, and `rooted_runtime_modified=0`.
5. Stop X11 through the APK, remove only the R12b run scopes and Termux helper
   state, and verify no process/listener residue, rollback preservation, and
   recovered free space. Do not launch Steam after extraction.

## Interpretation

- A pass closes the APK asset/materialization and clean-device Holo extraction
  boundary without a rooted bootstrap dependency.
- A failure must be classified as helper materialization, bootstrap runtime
  dependency, archive extraction, or cleanup before another variable changes.
- Only after a pushed R12b result should the next run return to the native
  Steam updater lifecycle that R11 isolated.
