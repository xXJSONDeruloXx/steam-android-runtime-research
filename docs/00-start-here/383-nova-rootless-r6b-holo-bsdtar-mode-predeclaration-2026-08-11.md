# Nova rootless R6b — Holo `bsdtar` mode retry predeclaration — 2026-08-11

Run ID: `nova-rootless-r6b-20260811T054200Z`
Sub-run: `R6b-holo-bsdtar-mode`
Status: predeclared; the prior R6 tree will be cleaned before launch.

## Controlled change

R6 proved that Holo `bsdtar` can read the verified archive through app-UID
PRoot, but its `-xpf` invocation preserved an unreadable archive mode despite
`--no-same-permissions`. R6b changes only that invocation to `-xf` and creates
the declared PRoot temporary directory before execution. The PRoot library
staging retains `libtalloc.so` and `libtalloc.so.2` symlinks, as required by
R6's first executable attempt.

The rooted Holo tree remains a read-only bootstrap input. R6b does not copy or
modify it, use `su`, `chroot`, or `mount`, and does not treat it as rootless
evidence. The archive candidate, closure, state, PRoot files, and packages
remain app-owned.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `6498004` (`fix: make rootless archive modes app-readable`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `e60c53de5e741e5109cfc1bd0d82f473dd600da7a3414c736aed6f8e8e53843e`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- `libtalloc.so.2.4.3` SHA-256:
  `3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r6b-20260811T054200Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r6b-20260811T054200Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  guest-rootfs-closure/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

The rooted rollback paths are outside scope and must remain unchanged:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication data is exported, copied, or placed in the R6b tree.

## Run sequence and acceptance

1. Remove only the R6 app-private and remote staging trees after recording
   their cleanup state. Verify no R6 process remains, the device has the
   required free space, and the rooted rollback paths still exist.
2. Install and hash the pinned APK, stage the archive/PRoot closure/manifests,
   and verify the archive and artifact hashes as the app UID. Do not
   pre-create either atomic rootfs destination.
3. Run the app-UID archive helper with the versioned rooted Holo tree as the
   read-only bootstrap. Require no PRoot temp warning, the archive marker,
   required glibc/pacman paths, app ownership, and atomic activation.
4. Run the existing package-closure helper into `guest-rootfs-closure/` with
   an empty app-owned Steam-client directory. Require all 44 Holo package
   hashes, both Debian asset hashes, the closure marker, GTK2/audio library
   paths, and no partial destination. This gate does not claim a SteamUI
   `ldd` result until the real client is seeded.
5. Stop and document at the first failed gate. Do not start Steam or
   Termux:X11 in this sub-run.

## Cleanup

Capture extractor and closure logs, remove only the named R6b remote and
app-private trees after documenting the result, verify no PRoot/bsdtar process
or temporary staging directory remains, and confirm the rooted rollback paths
are unchanged.

