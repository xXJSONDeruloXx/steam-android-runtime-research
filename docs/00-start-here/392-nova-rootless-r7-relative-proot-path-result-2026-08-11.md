# Nova rootless R7 — relative PRoot path result — 2026-08-11

Run ID: `nova-rootless-r7-steam-seed-20260811T060538Z`
Sub-run: `R7-steam-seed-supervisor`
Status: stopped at the archive-extraction invocation boundary; no guest
candidate or Steam process was activated.

## Result

The fresh R7 app-owned payload was staged and verified before the extraction
call:

```text
app_uid=10128
rootfs_archive=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
steamui.so=present
holo_package_count=103
steamrtarm32=steamrtarm64
```

The first extraction invocation passed relative app paths for PRoot, its
loader, and the PRoot library directory. The helper entered its atomic staging
path, then Android's linker rejected the PRoot executable:

```text
nova_rootless_rootfs_archive=extract archive=files/rootless-r7-steam-seed-20260811T060538Z/rootfs-archive/system.rootfs.zst stage=files/rootless-r7-steam-seed-20260811T060538Z/.guest-rootfs.archive-staging.28387
CANNOT LINK EXECUTABLE "files/rootless-r7-steam-seed-20260811T060538Z/proot/proot": library "libtalloc.so.2" not found: needed by main executable
nova_rootless_rootfs_archive=fail reason=proot_bsdtar_extract
```

The helper's failure trap removed the partial atomic guest-rootfs staging
directory. No `guest-rootfs/` candidate was activated, and no Steam, PRoot,
pacman, bsdtar, or Termux:X11 process remained. The rooted runtime was not
modified.

## Classification

This is an invocation-path failure, not evidence that the public ARM64 Steam
seed, Holo package closure, or `steamui.so` ABI is incompatible. The same
app-private files were readable and hash-verified; the failure happened before
the bootstrap PRoot could execute Holo `bsdtar`. The helper already accepts
absolute paths, so this result does not justify changing the helper or the
package/seed inputs.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `4a84957` (`docs: predeclare rootless R7 Steam seed run`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Rooted bootstrap input:
  `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`.

No Steam authentication data was exported, copied, or staged.

## Cleanup and next boundary

The exact R7 app-private and remote trees must be removed before the retry;
the retry must use a new run identity and absolute app-private paths for
`NOVA_ROOTLESS_PROOT_BIN`, `NOVA_ROOTLESS_PROOT_LOADER`, and
`NOVA_ROOTLESS_PROOT_LIB_DIR`. Re-run the unchanged extraction helper first,
then proceed to the seed-bound closure only if extraction passes.

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```
