# Nova rootless R7b — PRoot `libtalloc` soname result — 2026-08-11

Run ID: `nova-rootless-r7b-absolute-proot-20260811T061455Z`
Sub-run: `R7b-absolute-proot-path`
Status: stopped at the PRoot loader boundary; no guest candidate or Steam
process was activated.

## Result

R7b restaged the same public artifacts under a fresh scope. The archive and
package gates passed before extraction:

```text
archive=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
packages=103
client_layout=pass
```

The unchanged extractor was invoked with absolute app-private paths for the
archive, PRoot, loader, library directory, state, and destination. It reached
the absolute PRoot executable but the linker could not resolve the required
soname:

```text
nova_rootless_rootfs_archive=extract archive=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7b-absolute-proot-20260811T061455Z/rootfs-archive/system.rootfs.zst stage=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7b-absolute-proot-20260811T061455Z/.guest-rootfs.archive-staging.28506
CANNOT LINK EXECUTABLE "/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7b-absolute-proot-20260811T061455Z/proot/proot": library "libtalloc.so.2" not found: needed by main executable
nova_rootless_rootfs_archive=fail reason=proot_bsdtar_extract
```

The app-owned library directory contained `libtalloc.so.2.4.3` and
`libandroid-shmem.so`, but no `libtalloc.so.2` soname symlink. The failure
trap removed the partial atomic destination; `guest-rootfs/` was absent. No
Steam, PRoot, pacman, bsdtar, or Termux:X11 process remained, and the rooted
runtime was not modified.

## Classification

This result closes the relative-path hypothesis from R7. Absolute PRoot paths
are accepted far enough to invoke the executable. The next failure is a
staging closure defect: the app-owned PRoot library set must include the
loader-visible `libtalloc.so.2 -> libtalloc.so.2.4.3` soname link (and the
unversioned compatibility link used by the known-good R6 staging). This does
not yet classify the Steam seed or `steamui.so` ABI, because Holo `bsdtar` was
never launched.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `3e2bdbd` (`docs: predeclare rootless R7b path retry`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot `libtalloc` payload hash source:
  `android/nova-lab/build/rootless-termux/libtalloc_2.4.3_aarch64-data/data/data/com.termux/files/usr/lib/libtalloc.so.2.4.3`.

No Steam authentication data was exported, copied, or staged.

## Cleanup and next boundary

The exact R7b app-private and remote trees must be removed before the next
retry. The retry must create only the declared soname links in the app-owned
PRoot library directory, then rerun the unchanged extractor with the same
absolute paths. Do not change the helper, seed, or Holo closure until that
loader gate passes.

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```
