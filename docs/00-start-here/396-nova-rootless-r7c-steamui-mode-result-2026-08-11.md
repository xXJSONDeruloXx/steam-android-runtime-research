# Nova rootless R7c — public seed `steamui.so` mode result — 2026-08-11

Run ID: `nova-rootless-r7c-libtalloc-soname-20260811T061708Z`
Sub-run: `R7c-libtalloc-soname`
Status: archive extraction passed; seed-bound closure stopped at the
`steamui.so` file-mode gate.

## Result

R7c created the declared `libtalloc` soname links and the unchanged archive
extractor passed atomically:

```text
nova_rootless_rootfs_archive=pass rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7c-libtalloc-soname-20260811T061708Z/guest-rootfs
```

The unchanged guest closure copied the fresh Holo candidate and processed all
103 Holo packages plus the two Debian GTK2 assets. It then reached the
seed-bound `steamui.so` check and stopped with:

```text
ldd: warning: you do not have execution permission for `/opt/nova-steam/steamrtarm64/steamui.so`
nova_rootless_guest_rootfs=fail reason=guest_install
```

The app-owned seed confirmed the cause:

```text
-rw-rw-rw- ... steamui.so
```

The closure failure trap removed the partial `guest-rootfs-closure/`; the
extracted `guest-rootfs/` was not treated as a candidate. No Steam,
Termux:X11, or supervisor process was launched. The rooted runtime was not
modified.

## Classification

This is a public-seed extraction-mode boundary, not a `steamui.so` ABI or
library-resolution result. The ZIP extraction used for this test produced
read/write files without the executable bit, while the Holo `ldd` tool requires
the target shared object to be executable for its probe. The next retry may
normalize executable mode only inside the app-owned public `steam-client/`
tree, then must rerun the unchanged extractor and closure. No helper or
SteamUI patch is justified by this result.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `cddab02` (`docs: predeclare rootless R7c libtalloc retry`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.

No Steam authentication data was exported, copied, or staged.

## Cleanup and next boundary

Remove the exact R7c app-private and remote trees before the retry. The next
run must add only explicit executable mode normalization for the public seed
ELF targets, retain the two `libtalloc` links, and repeat the unchanged
archive/closure helpers. Do not start Steam or Termux:X11 until that closure
gate passes.

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```
