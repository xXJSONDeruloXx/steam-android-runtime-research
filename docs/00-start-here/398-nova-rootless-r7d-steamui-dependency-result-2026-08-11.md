# Nova rootless R7d — `steamui.so` dependency closure result — 2026-08-11

Run ID: `nova-rootless-r7d-steam-seed-mode-20260811T062111Z`
Sub-run: `R7d-steam-seed-mode`
Status: archive extraction passed; the seed-bound closure reached and failed
the real `steamui.so` dependency check.

## Result

The R7d mode normalization removed the prior probe-mode failure. The archive
extractor passed atomically:

```text
nova_rootless_rootfs_archive=pass rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7d-steam-seed-mode-20260811T062111Z/guest-rootfs
```

The unchanged guest closure then copied the fresh candidate, processed all 103
Holo packages and both Debian GTK2 assets, and completed the normal package
hooks. `ldd` no longer emitted the R7c execution-permission warning. The
closure still stopped at the intentional missing-dependency gate:

```text
nova_rootless_guest_rootfs=fail reason=guest_install
```

The helper's `steamui.so` check is:

```text
/usr/bin/ldd /opt/nova-steam/steamrtarm64/steamui.so | /usr/bin/grep -F "not found"
```

Therefore this result proves that the Holo guest can execute the probe but
does not yet provide every runtime library required by the public ARM64
SteamUI binary. The helper trap removed the partial
`guest-rootfs-closure/`; the extracted `guest-rootfs/` was not activated as a
candidate.

No Steam binary, supervisor, Termux:X11 server, display, network, audio,
controller, login, or game path was started. The rooted runtime was not
modified.

## Classification

This is the first genuine seed-to-Holo library-closure boundary in the
rootless track. It is no longer a path, soname, or file-mode failure, and it
is not yet evidence of a display/WSI problem. The exact missing library names
must be captured in a separate diagnostic run before adding any package or
loader workaround. Do not patch SteamUI or broaden the closure speculatively.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `db5ffe3` (`docs: predeclare rootless R7d seed mode retry`).
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

Remove only the exact R7d app-private and remote trees before the diagnostic
retry. The diagnostic must preserve the same public seed, mode normalization,
absolute PRoot paths, and package closure, but capture complete guest-side
`ldd` output against a passing closure candidate. Only after the missing names
are known should any narrowly matched dependency be added.

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```
