# Nova rootless R6 — Holo `bsdtar` bootstrap predeclaration — 2026-08-11

Run ID: `nova-rootless-r6-20260811T053311Z`
Sub-run: `R6-holo-bsdtar-bootstrap`
Status: predeclared; no R6 device process has started.

## Controlled change

R5c closed the toybox extraction path: its human-readable `tar -t` output
could not be used as a lossless member manifest for this Holo archive. R6
changes only the archive extraction engine. The app-UID helper will execute
the verified Holo ARM64 guest `/usr/bin/bsdtar` through the already verified
ARM64 PRoot loader, binding the verified archive and an app-private staging
directory. `--no-same-owner --no-same-permissions` is required so the helper
does not attempt to recreate root-owned metadata.

The staged PRoot library directory must preserve the Termux package's
`libtalloc.so` and `libtalloc.so.2` symlinks to `libtalloc.so.2.4.3`; the
first setup invocation showed that copying only the versioned file is not a
usable PRoot closure. This is a staging invariant, not a change to the
archive extractor.

The existing rooted Holo rootfs is a read-only bootstrap input for this
experiment only. R6 does not copy it as the guest candidate, modify it, use
`su`, `chroot`, or `mount`, or treat rooted paths as rootless evidence. The
candidate, state, archive, PRoot files, and package inputs remain app-owned.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `714266d` (`fix: extract rootless rootfs with Holo bsdtar`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `2eb2b4bd0f61c293b60f3ae581dfbf31a80d1ee5416530769d2229cb6f45527f`.
- Holo archive: `system.rootfs.zst`, 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- `libandroid-shmem.so` SHA-256:
  `84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731`.
- `libtalloc.so.2.4.3` SHA-256:
  `3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb`.
- APK `nova-zstd` SHA-256:
  `a9a743377cbf0580f4ed02dc363e77a1cd275987283c1bc655e1ab17ca6629a4`.
- SteamUI Holo package manifest SHA-256:
  `6583d0a34da45418d82dba9afa369acc22881fc318550b1a4c876c4235241fae`.
- External GTK2 asset manifest SHA-256:
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.

## Exact mutable scope

The named remote push tree is disposable staging only:

```text
/data/local/tmp/nova-rootless-r6-20260811T053311Z/
```

The app-private run tree is the only candidate/state scope:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r6-20260811T053311Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  guest-rootfs-closure/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

The rooted rollback paths are outside scope and must remain present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
/data/local/tmp/nova-holo-rootfs
```

The last path is expected to be absent on this device; its absence must not
be “repaired” during R6. No Steam authentication data is exported, copied,
or included in the run tree.

## Run sequence and acceptance

1. Verify no R5 process, display, socket, or run tree remains; verify the
   rooted rollback paths and the device free-space gate without modifying
   them. Install the pinned APK and record the installed package state.
2. Stage the archive, PRoot loader/library closure, extractor, profile, and
   manifests under the named R6 tree. Verify the archive size/SHA-256 and
   artifact ownership as the app UID.
3. Run `nova-rootless-extract-rootfs.sh prepare` as the non-root app UID with
   `NOVA_ROOTLESS_BOOTSTRAP_ROOTFS` pointing at the existing versioned Holo
   rootfs. Require `proot_bsdtar_extract` to exit successfully, the required
   glibc/pacman paths, the archive marker, and atomic candidate activation.
4. If extraction passes, run the existing app-owned SteamUI closure helper
   into `guest-rootfs-closure/`. Require its package marker and libraries.
   The first closure gate uses an empty app-owned Steam-client directory and
   therefore does not claim a SteamUI `ldd` result; a later client-seeded gate
   must provide the client and require clean `ldd steamui.so` output. If either
   gate fails, stop at that boundary and document it before changing another
   variable.
5. Do not start Steam, Termux:X11, or a login session in this extraction
   sub-run. A later bounded sub-run may use the candidate after this result is
   committed and pushed.

## Cleanup

Capture the complete extractor/PRoot output, stop only R6 process IDs, remove
the named R6 remote push tree and app-private tree after documenting the
result, verify no R6 process or temporary PRoot bind remains, and confirm the
rooted rollback paths are unchanged. Preserve the exact archive and artifact
hashes in the result document.
