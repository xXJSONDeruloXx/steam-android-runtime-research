# Nova rootless R12d — explicit guest library path result — 2026-08-11

Run ID: `nova-rootless-r12d-env-library-path-20260811T090916Z`
Sub-run: `R12d-rootless-apk-materialized-env-library-path`
Status: failed at the bootstrap default-library-layout boundary; the run was
cleaned exactly.

## Result

R12d proved that the new guest-side command was reached: the bootstrap
`/usr/bin/env` started under PRoot. It then failed before launching `bsdtar`
because the bootstrap loader could not find `libc.so.6`:

```text
nova_rootless_rootfs_archive=extract archive=files/r12d/system.rootfs.zst stage=files/r12d/.guest-rootfs.archive-staging.5366
/usr/bin/env: error while loading shared libraries: libc.so.6: cannot open shared object file: No such file or directory
nova_rootless_rootfs_archive=fail reason=proot_bsdtar_extract
```

This is the expected diagnostic separation from R12c. R12c's direct
`bsdtar` invocation could not resolve `libarchive.so.13`; R12d's explicit
`LD_LIBRARY_PATH=/lib:/usr/lib` was applied by `env`, but `env` itself could
not start with the libraries staged only in `/lib`. The bootstrap must
therefore materialize its regular libraries in the loader's default `/usr/lib`
layout, or otherwise provide a loader-visible `/usr/lib` path. The Holo
archive, PRoot, and network paths are not implicated.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: `421-nova-rootless-r12d-env-library-path-predeclaration`.
- Code under test: commit `2beb437` (`fix: set guest library path for
  rootless bootstrap`); predeclaration commit `42d3245`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `c6994eab79331e72c488b52ad3abdedd03a39e13187107caeba6e627ff310395`.
- Generated bootstrap manifest: 18 payload entries, SHA-256
  `4c84781a5be01d92d41ab5b002746f6cbde39586501b11775e4956f563cb9806`.
- App-owned bootstrap `/usr/bin/env` SHA-256:
  `3c093be867d02571a468c5108607b74592b3f2417597971c79845723d103b222`.
- App-owned `libarchive.so.13` SHA-256:
  `7dbc40ba18eec470195458940fb277144487fcd90f035d3e8007023b78561079`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh app-UID Termux:X11 transport passed on `127.0.0.1:6077`.
- No Steam command, Steam data, authentication data, Proton, or display
  session was started. The rooted rollback image was not used or modified.

## Exact cleanup verification

Only these R12d run scopes were removed:

```text
/data/local/tmp/nova-rootless-r12d-env-library-path-20260811T090916Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12d/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK asset cache under `files/launcher/` was retained for
inspection. After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_r12d=absent
app_r12d=absent
termux_rootless=absent
rollback_rootfs=present
active_marker=present
free_space=86117252 KiB
```

## Decision and next boundary

Keep the explicit `env` invocation; it reached the intended guest command and
gave a useful loader error. Make exactly one controlled packaging change for
R12e: stage the existing pinned library closure under
`nova-bsdtar-bootstrap/rootfs/usr/lib` (preserving the loader and `env` in
their current locations), update the manifest and APK asset list, and rerun
only the same extraction gate. If `env` then starts and `bsdtar` reports a
different missing dependency, record that dependency rather than changing
the archive or PRoot inputs.
